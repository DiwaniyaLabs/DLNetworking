//
//  DLNetworkingGameKit.m
//  Diwaniya Client
//
//  Created by Sour on 6/18/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "DLNetworkingGameKit.h"

@implementation DLNetworkingGameKit

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate withSessionID:(NSString *)sessionID
{
	if ( (self = [super initWithDelegate:delegate]) )
	{
		// save our session ID for when we want to broadcast/listen
		_sessionID = sessionID;
		
		// set the protocol
		protocol = DLProtocolGameKit;
	}
	
	return self;
}

-(void)removeAllDelegates
{
	if (currentPeer)
		currentPeer.session.delegate = nil;
	
	for (DLNetworkingPeer *peer in networkingPeers)
		peer.session.delegate = nil;
}

#pragma mark -
#pragma mark Peer Setup

-(BOOL)startListening
{
	// create session - nil for displayName will get the device name
	GKSession *session = [[GKSession alloc] initWithSessionID:_sessionID displayName:nil sessionMode:GKSessionModeServer];
	
	// session could not be created?
	if (!session)
	{
		NSLog(@"DLNetworking failed to initialize GameKit session.");
		return NO;
	}
	
	// set delegate to receive notifications
	session.delegate = self;
	
	// set to receive network packets
	[session setDataReceiveHandler:self withContext:nil];
	
	// create a new peer for this
	currentPeer = [DLNetworkingPeer peerWithConnection:session andPeerID:session.peerID andName:nil];
	
	// start listening
	currentPeer.session.available = YES;
	
	// this will set isListening
	return [super startListening];
}

-(void)stopListening
{
	// destroy object
	if (!isInitializedForDiscovering)
		return;
	
	// if nobody's even connected, nil the currentPeer
	if (self.numberOfConnectedPeers == 0)
		currentPeer = 0;
	// stop listening
	else
		currentPeer.session.available = NO;				// BUG: this might actually be disconnecting the session
	
	// this will set isListening
	[super stopListening];
}

-(BOOL)startDiscovering
{
	// create session
	GKSession *session = [[GKSession alloc] initWithSessionID:_sessionID displayName:nil sessionMode:GKSessionModeClient];

	// session could not be created?
	if (!session)
	{
		NSLog(@"DLNetworking failed to initialize GameKit session.");
		return NO;
	}

	// set delegate to receive notifications
	session.delegate = self;

	// set to receive network packets
	[session setDataReceiveHandler:self withContext:nil];

	// create a new peer for this
	currentPeer = [DLNetworkingPeer peerWithConnection:session andPeerID:session.peerID andName:nil];
	
	// be connectable
	currentPeer.session.available = YES;
	
	// we also need the discovered peers array
	discoveredPeers = [[NSMutableArray alloc] init];
	
	// this will set isDiscovering
	return [super startDiscovering];
}

-(void)stopDiscovering
{
	if (!isInitializedForDiscovering)
		return;
	
	// stop discovering
	currentPeer.session.available = NO;
	
	// this will set isDiscovering
	[super stopDiscovering];
}

#pragma mark -
#pragma mark Peer Connectivity

-(BOOL)connectToInstance:(DLNetworking *)instance;
{
	NSLog(@"DLNetworking does not support connecting to an instance via GameKit.");
	return NO;
}

-(BOOL)connectToServer:(DLNetworkingPeer *)peer
{
	// server trying to connect? NO!
	if (isInitializedForListening)
	{
		NSLog(@"DLNetworking can not connect to a host if it's initialized as a server.");
		return NO;
	}
	
	// already connected?
	if (isConnected)
	{
		NSLog(@"DLNetworking instance is already connected to a host.");
		return NO;
	}
	
	// make sure our session is initialized
	if (!currentPeer)
	{
		NSLog(@"DLNetworking could not connect to peer. Start discovering peers before trying to connect.");
		return NO;
	}
	
	// take down the name of the server, so we know who to listen to
	_peerServerID = peer.peerID;

	// attempt to connect
	[currentPeer.session connectToPeer:peer.peerID withTimeout:5];
	
	return YES;
}

-(void)disconnect
{
	// just disconnect
	[currentPeer.session disconnectFromAllPeers];
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	// disconnect peer
	[currentPeer.session disconnectPeerFromAllPeers:peer.peerID];
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(NSArray *)peerIDsFromPeers:(NSArray *)peers except:(DLNetworkingPeer *)peerException
{
	int numPeers = peers.count;
	NSMutableArray *peerIDs = [[NSMutableArray alloc] initWithCapacity:numPeers];
	
	for (DLNetworkingPeer *peer in peers)
	{
		if (peer == peerException)
			continue;
		
		[peerIDs addObject:peer.peerID];
	}
	
	return peerIDs;
}

-(void)GKSendPacket:(NSData *)packet toPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer
{
	// get the peerIDs from every peer except Local Instances, which will be dealt with by this method
	NSArray *peerIDs = [self peerIDsFromPeers:peers except:peer];
	
	NSError *error;
	[currentPeer.session sendData:packet toPeers:peerIDs withDataMode:GKSendDataReliable error:&error];
}

-(void)GKSendPacketToAll:(NSData *)packet
{
	NSError *error;
	[currentPeer.session sendDataToAllPeers:packet withDataMode:GKSendDataReliable error:&error];
}

#pragma mark -
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:@[ peer ] except:nil];
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:peers except:nil];
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:peers except:peer];
}

-(void)sendToAll:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacketToAll:packet];
}

-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// create the packet
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send packet
	[self GKSendPacket:packet toPeers:networkingPeers except:peer];
}

-(void)sendToServer:(char)packetType, ...
{	
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// get the peer handler
	DLNetworkingPeer *peer = [self peerFromPeerID:_peerServerID];
	
	// the server could only be a GK instance, not a local instance
	[self GKSendPacket:packet toPeers:@[peer] except:nil];
}

#pragma mark -
#pragma mark GKSessionDelegate

// CONNECT/DISCONNECT/DISCOVER
-(void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	switch (state)
	{
		// DISCOVERY: notify delegate of newly discovered hosts
		case GKPeerStateAvailable:
		case GKPeerStateUnavailable:
		{
			// make sure the session is available and wants these notifications
			if (session.isAvailable && [_delegate respondsToSelector:@selector(networking:didDiscoverPeers:)])
			{
				// adding a peer?
				if (state == GKPeerStateAvailable)
				{
					// create "empty" peer
					DLNetworkingPeer *peer = [DLNetworkingPeer peerWithConnection:nil andPeerID:peerID andName:[currentPeer.session displayNameForPeer:peerID]];
					
					// add to array
					[discoveredPeers addObject:peer];
				}
				// removing a peer?
				else
				{
					for (DLNetworkingPeer *peer in discoveredPeers)
					{
						// find the peer in question
						if ([peer isEqualWithPeerID:peerID])
						{
							// remove it and stop
							[discoveredPeers removeObject:peer];
							break;
						}
					}
				}
				
				// notify delegate
				[_delegate networking:self didDiscoverPeers:discoveredPeers];
			}
			
			break;
		}
		// CONNECTIVITY
		case GKPeerStateConnected:
		{
			// Only allow the peer if this instance is
			// 1. A server
			// 2. A client that just connected specifically to the server
			// which means the client is going to be ignoring all other clients (p2p)
			if (isInitializedForListening)
			{
				DLNetworkingPeer *peer = [DLNetworkingPeer peerWithConnection:session andPeerID:peerID andName:nil];
				
				[self addPeer:peer];
				
				[_delegate networking:self didConnectToPeer:peer];
			}
			else if ([_peerServerID isEqualToString:peerID])
			{
				DLNetworkingPeer *peer = [DLNetworkingPeer peerWithConnection:session andPeerID:peerID andName:nil];
				
				[self addPeer:peer];
				
				[_delegate networking:self didConnectToServer:peer];
			}
			
			break;
		}
		case GKPeerStateDisconnected:
		{
			// find the peer using the peerID
			DLNetworkingPeer *peer = [self peerFromPeerID:peerID];
			
			// on the server, remove the peer
			if (isInitializedForListening)
			{
				// remove the peer
				[self removePeer:peer];

				// notify delegate
				[SafeDelegateFromPeer(peer) networking:self didDisconnectPeer:peer withError:nil];
			}
			// on the client, only remove peer if it's the server
			else
			{
				// ignore any packets from anyone other than the server
				if (![_peerServerID isEqualToString:peerID])
					break;
				
				[self removePeer:peer];
				
				// notify delegate
				[SafeDelegateFromPeer(peer) networking:self didDisconnectWithError:[self createErrorWithCode:DLNetworkingErrorConnectionClosed]];
			}
			
			break;
		}
		default: break;
	}
}

// CONNECTION REQUEST
-(void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	NSError *error;
	
	// accept connection right away, since we're broadcasting
	if (![session acceptConnectionFromPeer:peerID error:&error])
	{
		NSLog(@"DLNetworking failed to accept connection from %@. Reason: %@", peerID, error.localizedFailureReason);
		return;
	}
	
	// nothing else is done here! we'll just wait for the "Connected" message
}

// CONNECTION FAILURE
-(void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	NSLog(@"DLNetworking encountered a 'connectionWithPeerFailed'. Reason: %@", error.localizedFailureReason);
}

// RECEIVE PACKET
-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
	DLNetworkingPeer *peerSender = [self peerFromPeerID:peer];
	
	if (!peerSender)
	{
		NSLog(@"DLNetworking encountered an error. Could not determinee the sender of the packet.");
		return;
	}
	
	// notify delegate
	[SafeDelegateFromPeer(peerSender) networking:self didReceivePacket:data fromPeer:peerSender];
}

// INITIALIZATION ERRORS
-(void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	NSLog(@"DLNetworking encountered a 'didFailWithError'. Reason: %@", error.localizedFailureReason);
}

@end

#endif