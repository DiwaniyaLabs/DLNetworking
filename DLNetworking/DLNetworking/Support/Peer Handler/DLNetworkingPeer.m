//
//  DLNetworkingPeer.m
//  Diwaniya Client
//
//  Created by Sour on 6/17/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "DLNetworkingPeer.h"

@implementation DLNetworkingPeer

@synthesize peerName;
@synthesize peerID;
@synthesize delegate;
@synthesize peerConnection;
@synthesize isDummy = _isDummy;

#pragma mark -
#pragma mark Initialization

+(DLNetworkingPeer *)peerWithConnection:(id)_peerConnection
{
	return [[DLNetworkingPeer alloc] initWithPeerConnection:_peerConnection andPeerID:nil andName:nil];
}

+(DLNetworkingPeer *)peerWithConnection:(id)_peerConnection andPeerID:(NSString *)_peerID andName:(NSString *)_peerName
{
	return [[DLNetworkingPeer alloc] initWithPeerConnection:_peerConnection andPeerID:_peerID andName:_peerName];
}

-(id)initWithPeerConnection:(id<NSObject>)_peerConnection andPeerID:(NSString *)_peerID andName:(NSString *)_peerName
{
	if ( (self = [super init]) )
	{
		// set connection
		self.peerConnection = _peerConnection;
		
		// set peer ID
		self.peerID = _peerID;
		
		// set name
		self.peerName = _peerName;
		
		_isDummy = NO;
	}
	
	return self;
}

-(void)dealloc
{
	peerConnection = nil;
}
		 
#pragma mark -
#pragma mark User Data

-(void)setUserValue:(id)value forKey:(NSString *)key
{
	if (userObjects == nil)
		userObjects = [[NSMutableDictionary alloc] init];
	
	// if the value we're trying to add is nil, that means remove the object
	if (value == nil)
		[userObjects removeObjectForKey:key];
	
	// add the value to the dictionary
	[userObjects setValue:value forKey:key];
}

-(id)userValueForKey:(NSString *)key
{
	if (userObjects == nil)
		return nil;
	
	// return the value associated with key
	return [userObjects valueForKey:key];
}

#pragma mark -
#pragma mark Comparison

-(BOOL)isEqualWithPeerID:(NSString *)_peerID;
{
	return ([peerID isEqual:_peerID]);
}

-(BOOL)isEqualWithPeerConnection:(id)_peerConnection
{
	return ([peerConnection isEqual:_peerConnection]);
}

#pragma mark -
#pragma mark Connection Returns

-(GCDAsyncSocket *)socket
{
	return peerConnection;
}

-(GKSession *)session
{
	return peerConnection;
}

@end
