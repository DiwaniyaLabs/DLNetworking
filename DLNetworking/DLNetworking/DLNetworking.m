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

#import "DLNetworkingSockets.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import "DLNetworkingGameKit.h"
#endif

@implementation DLNetworking

@synthesize protocol;
@synthesize currentPeer;
@synthesize isConnected, isInitializedForListening, isInitializedForDiscovering, isListening, isDiscovering;

#pragma mark -
#pragma mark Initialization

+(DLNetworking *)networkingViaSockets:(id<DLNetworkingDelegate>)delegate withPort:(uint16_t)port
{
	return [[DLNetworkingSockets alloc] initWithDelegate:delegate withPort:port];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
+(DLNetworking *)networkingViaGameKit:(id<DLNetworkingDelegate>)delegate withSessionID:(NSString *)sessionID
{
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

-(void)setDelegate:(id<DLNetworkingDelegate>)delegate;
{
	// change the delegate
	_delegate = (id<DLNetworkingClientDelegate,DLNetworkingServerDelegate>)delegate;
}

-(void)setDelegate:(id<DLNetworkingDelegate>)delegate forPeer:(DLNetworkingPeer *)peer
{
	// set the user's delegate
	peer.delegate = delegate;
}

-(void)removeAllDelegates
{
	// abstract method
}

-(void)dealloc
{
	// remove all delegates first
	[self removeAllDelegates];
	
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

-(BOOL)removePeerWithPeerID:(NSString *)peerID
{
	for (DLNetworkingPeer *peer in networkingPeers)
	{
		// if found, delete and return
		if ([peer isEqualWithPeerID:peerID])
		{
			[networkingPeers removeObject:peer];
			return YES;
		}
	}
	
	return NO;
}

-(BOOL)removePeerWithConnectionID:(id)connectionID
{
	for (DLNetworkingPeer *peer in networkingPeers)
	{
		// if found, delete and return
		if ([peer isEqualWithPeerConnection:connectionID])
		{
			[networkingPeers removeObject:peer];
			return YES;
		}
	}
	
	return NO;
}

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
	
	return nil;
}

#pragma mark -
#pragma mark Peer Setup

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
#pragma mark Peer Connectivity

-(BOOL)connectToPeer:(id)peer
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

@end
