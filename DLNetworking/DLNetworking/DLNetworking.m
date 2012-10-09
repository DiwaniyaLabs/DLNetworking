//
//  DLNetworking.m
//  Diwaniya Network
//
//  Created by Sour on 6/16/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "DLNetworkingDummyClient.h"
#import "DLNetworkingSocketAD.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import "DLNetworkingGameKitAD.h"
#endif

@implementation DLNetworking

@synthesize protocol;
@synthesize currentPeer;
@synthesize isConnected, isInitializedForListening, isInitializedForDiscovering, isListening, isDiscovering;

#pragma mark -
#pragma mark Initialization

+(DLNetworking *)networkingViaDummyClient:(id<DLNetworkingDelegate>)delegate
{
	return [[DLNetworkingDummyClient alloc] initWithDelegate:delegate];
}

+(DLNetworking *)networkingViaSocket:(id<DLNetworkingDelegate>)delegate withPort:(uint16_t)port allowDummies:(BOOL)allowDummies
{
	if (allowDummies)
		return [[DLNetworkingSocketAD alloc] initWithDelegate:delegate withPort:port];
	else
		return [[DLNetworkingSocket alloc] initWithDelegate:delegate withPort:port];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
+(DLNetworking *)networkingViaGameKit:(id<DLNetworkingDelegate>)delegate withSessionID:(NSString *)sessionID allowDummies:(BOOL)allowDummies
{
	if (allowDummies)
		return [[DLNetworkingGameKitAD alloc] initWithDelegate:delegate withSessionID:sessionID];
	else
		return [[DLNetworkingGameKit alloc] initWithDelegate:delegate withSessionID:sessionID];
}
#endif

-(id)initWithDelegate:(id)delegate
{
	if ( (self = [super init]) )
	{
		// set the delegate
		_delegate = delegate;
		
		// make sure this start uninitialized
		currentPeer = nil;
		
		// set up clients
		networkingPeers = [[NSMutableArray alloc] init];
		
		// initially not connected
		isConnected = NO;
		
		// not listening initially
		isInitializedForListening = NO;
		
		// not discovering initially
		isInitializedForDiscovering = NO;
	}
	
	return self;
}

-(void)setDelegate:(id<DLNetworkingDelegate>)delegate forPeer:(DLNetworkingPeer *)peer
{
	// set the user's delegate
	peer.delegate = delegate;
}

-(void)setDelegateForAllPeers:(id<DLNetworkingServerDelegate,DLNetworkingClientDelegate>)delegate;
{
	_delegate = delegate;
	
	if (currentPeer)
		currentPeer.delegate = delegate;
	
	for (DLNetworkingPeer *peer in networkingPeers)
		peer.delegate = delegate;
}

-(void)removeAllInnerDelegates
{
	// abstract
}

-(void)dealloc
{
	// remove all delegates first
	[self removeAllInnerDelegates];
	
	if (isInitializedForListening)
		[self stopListening];
	else if (isInitializedForDiscovering)
		[self stopDiscovering];

	if (isConnected)
		[self disconnect];

	// get rid of currentPeer
	currentPeer = nil;
}

#pragma mark -
#pragma mark DLNetworkingPeer

-(DLNetworkingPeer *)peerFromPeerID:(NSString *)peerID
{
	for (DLNetworkingPeer *peer in networkingPeers)
	{
		if ([peer isEqualWithPeerID:peerID])
			return peer;
	}
	
	return nil;
}

-(DLNetworkingPeer *)peerFromConnectionID:(id)connectionID
{
	for (DLNetworkingPeer *peer in networkingPeers)
	{
		if ([peer isEqualWithPeerConnection:connectionID])
			return peer;
	}
	
	if ([currentPeer isEqualWithPeerConnection:connectionID])
		return currentPeer;
	
	return nil;
}

#pragma mark -
#pragma mark Networking Setup

-(BOOL)startListening
{
	isInitializedForListening = YES;
	isListening = YES;
	return YES;
}

-(void)stopListening
{
	isListening = NO;
}

-(BOOL)startDiscovering
{
	isInitializedForDiscovering = YES;
	isDiscovering = YES;
	return YES;
}

-(void)stopDiscovering
{
	isDiscovering = NO;
}

#pragma mark -
#pragma mark Peer Events

-(void)addPeer:(DLNetworkingPeer *)peer
{
	// add the peer
	[networkingPeers addObject:peer];
	
	// set to connected
	isConnected = YES;
}

-(void)removePeer:(DLNetworkingPeer *)peer
{
	// remove peer
	[networkingPeers removeObject:peer];
	
	// no more peers connected
	if (networkingPeers.count == 0)
	{
		// set to not connected
		isConnected = NO;
	}
}

#pragma mark -
#pragma mark Peer Connectivity

-(BOOL)connectToInstance:(DLNetworking *)instance
{
	// abstract method
	return NO;
}

-(BOOL)connectToServer:(id)peer
{
	// abstract method
	return NO;
}

-(void)disconnect
{
	// abstract method
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer;
{
	// abstract method
}

#pragma mark -
#pragma mark Peer Queries

-(int)numberOfConnectedPeers
{
	return networkingPeers.count;
}

-(NSArray *)connectedPeers
{
	return networkingPeers;
}

-(NSArray *)discoveredPeers
{
	return discoveredPeers;
}

#pragma mark -
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// abstract method
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	// abstract method
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// abstract method
}

-(void)sendToAll:(char)packetType, ...
{
	// abstract method
}

-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// abstract method
}

-(void)sendToServer:(char)packetType, ...
{
	// abstract method
}

#pragma mark -
#pragma mark Packet Construction

-(NSData *)createPacket:(char)packetType withList:(va_list)args
{
	// packet type as an object
	NSNumber *packetTypeObj = [[NSNumber alloc] initWithChar:packetType];
	
	// put all parameters into array
	NSMutableArray *arrayPacket = [[NSMutableArray alloc] initWithObjects:packetTypeObj, nil];
	{
		// if there are more...
		id param;
		while ( (param = va_arg(args, id)) )
		{
			// add them to the array
			[arrayPacket addObject:param];
		}
	}
	
	// data to send
	return [NSKeyedArchiver archivedDataWithRootObject:arrayPacket];
}

#pragma mark -
#pragma mark Error Construction

-(NSError *)createErrorWithCode:(DLNetworkingError)errorCode
{
	NSString *description;
	NSString *recovery;
	
	if (errorCode == DLNetworkingErrorConnectionClosed)
	{
		description = @"You were disconnected from Diwaniya Network.";
		recovery = @"Please check your internet connection, and then try again.";
	}
	else if (errorCode == DLNetworkingErrorNotOnline)
	{
		description = @"You are not connected to the Internet.";
		recovery = @"Please connect via WiFi or cellular data. and then try again.";
	}
	else if (errorCode == DLNetworkingErrorConnectionRefused)
	{
		description = @"Could not connect to Diwaniya Network.";
		recovery = @"The server may be busy or under maintenance. Please check www.DiwaniyaLabs.com for updates.";
	}
	else if (errorCode == DLNetworkingErrorConnectionTimedOut)
	{
		description = @"Could not connect to Diwaniya Network.";
		recovery = @"Please check your internet connection, and then try again.";
	}
	else
	{
		errorCode = DLNetworkingErrorUnknown;
		description = @"Could not connect to Diwaniya Network.";
		recovery = @"Please make sure your Internet connection is functional, and then try again.";
	}
	
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
							  description, NSLocalizedDescriptionKey,
							  recovery, NSLocalizedRecoverySuggestionErrorKey, nil];
	
	return [[NSError alloc] initWithDomain:@"DLNetworking" code:errorCode userInfo:userInfo];
}

@end
