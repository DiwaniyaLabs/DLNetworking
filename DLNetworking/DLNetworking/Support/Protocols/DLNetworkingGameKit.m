//
//  DLNetworkingGameKit.m
//  Diwaniya Client
//
//  Created by Sour on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "DLNetworkingGameKit.h"

@implementation DLNetworkingGameKit (Helpers)

#pragma mark -
#pragma mark Helper methods

-(void)GKSendPacket:(NSData *)packet toPeers:(NSArray *)peerIDs
{
	NSError *error;
	[currentPeer.session sendData:packet toPeers:peerIDs withDataMode:GKSendDataReliable error:&error];
}

-(void)GKSendPacketToAll:(NSData *)packet
{
	NSError *error;
	[currentPeer.session sendDataToAllPeers:packet withDataMode:GKSendDataReliable error:&error];
}

@end

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
	currentPeer = [DLNetworkingPeer peerWithConnection:session];
	
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
	
	// stop listening
	currentPeer.session.available = NO;
	
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
	currentPeer = [DLNetworkingPeer peerWithConnection:session];
	
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

-(BOOL)connectToPeer:(DLNetworkingPeer *)peer
{
	// server trying to connect? NO!
	if (isServer)
	{
		NSLog(@"DLNetworking can not connect to a host if it's listening for connections.");
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
	
	// create "DUMMY" peer
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
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:[NSArray arrayWithObject:peer.peerID]];
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:peers];
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	NSMutableArray *peersToSendTo = [NSMutableArray arrayWithArray:peers];
	[peersToSendTo removeObject:peer];
	
	// send the packet
	[self GKSendPacket:packet toPeers:peersToSendTo];
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
	// new array for peer IDs
	NSMutableArray *peerIDs = [NSMutableArray arrayWithCapacity:networkingPeers.count];
	
	// loop over peers, adding them to the new array
	for (DLNetworkingPeer *curPeer in networkingPeers)
	{
		// also, skip the exception
		if (curPeer == peer)
			continue;
		
		[peerIDs addObject:curPeer.peerID];
	}
	
	if (peerIDs.count == 0)
		return;
	
	// create the packet
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send packet
	[self GKSendPacket:packet toPeers:peerIDs];
}

-(void)sendToServer:(char)packetType, ...
{	
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self GKSendPacket:packet toPeers:[NSArray arrayWithObject:_peerServerID]];
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
		case GKPeerStateConnected:
		{
			DLNetworkingPeer *peer;
			
			// on the server, we're adding all peers
			if (isInitializedForListening)
			{
				// create and add peer
				peer = [DLNetworkingPeer peerWithConnection:nil];
				peer.peerID = peerID;
				[networkingPeers addObject:peer];
				
				// set to connected
				isConnected = YES;
				
				// set to server
				isServer = YES;
				
				// notify delegate
				[_delegate networking:self didConnectToPeer:peer];
			}
			// on the client, we're only adding the server
			else
			{
				// make sure the peer is in fact the server
				if ([_peerServerID isEqualToString:peerID])
				{
					// create and add peer
					peer = [DLNetworkingPeer peerWithConnection:nil];
					peer.peerID = peerID;
					[networkingPeers addObject:peer];
					
					// set to connected
					isConnected = YES;

					// notify delegate
					[_delegate networking:self didConnectToServer:peer];
				}
				
				// which means the client is going to be ignoring all other clients
			}
			
			break;
		}
		case GKPeerStateDisconnected:
		{
			DLNetworkingPeer *peer = [self peerFromPeerID:peerID];
			
			// on the server, remove the peer
			if (isInitializedForListening)
			{
				// not found/removed?
				if (![self removePeerWithPeerID:peerID])
				{
					NSLog(@"DLNetworking encountered an error. Unidentified peer disconnected.");
					return;
				}
				
				// do we still have any connected peers?
				if (networkingPeers.count == 0)
				{
					// as well as current peer
//					currentPeer = nil;
					
					// set to not connected
					isConnected = NO;
					
					// set to not server
					isServer = NO;
				}
				
				// notify delegate
				[SafeDelegateFromPeer(peer) networking:self didDisconnectPeer:peer withError:nil];
			}
			// on the client, only remove peer if it's the server
			else
			{
				if ([_peerServerID isEqualToString:peerID])
				{
					// remove peer
					[self removePeerWithPeerID:peerID];
					
					// as well as current peer
					currentPeer = nil;
					
					// set to disconnected
					isConnected = NO;
					
					// notify delegate
					[_delegate networking:self didDisconnectWithError:nil];
				}
				
				// which means the client is going to be ignoring all other GameKit peer bullshit connected clients
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