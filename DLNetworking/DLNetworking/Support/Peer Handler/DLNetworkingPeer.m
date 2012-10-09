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

#import "DLNetworking.h"

@implementation DLNetworkingPeer

@synthesize peerName = _peerName;
@synthesize peerID = _peerID;
@synthesize delegate = _delegate;
@synthesize peerConnection = _peerConnection;
@synthesize isDummy = _isDummy;

#pragma mark -
#pragma mark Initialization

+(DLNetworkingPeer *)peerWithDelegate:(id<DLNetworkingDelegate>)delegate connection:(id)connection peerID:(NSString *)peerID name:(NSString *)name
{
	return [[self alloc] initWithDelegate:delegate connection:connection peerID:peerID name:name];
}

-(id)initWithDelegate:(id<DLNetworkingDelegate>)delegate connection:(id)connection peerID:(NSString *)peerID name:(NSString *)name
{
	if ( (self = [super init]) )
	{
		// set everything we just received
		_delegate = delegate;
		_peerConnection = connection;
		_peerID = peerID;
		_peerName = name;
		
		// not a dummy
		_isDummy = NO;
	}
	
	return self;
}

-(void)dealloc
{
	// TODO: not sure if this is still needed
	_peerConnection = nil;
}
		 
#pragma mark -
#pragma mark User Data

-(void)setUserValue:(id)value forKey:(NSString *)key
{
	if (_userObjects == nil)
		_userObjects = [[NSMutableDictionary alloc] init];
	
	// if the value we're trying to add is nil, that means remove the object
	if (value == nil)
		[_userObjects removeObjectForKey:key];
	
	// add the value to the dictionary
	[_userObjects setValue:value forKey:key];
}

-(id)userValueForKey:(NSString *)key
{
	if (_userObjects == nil)
		return nil;
	
	// return the value associated with key
	return [_userObjects valueForKey:key];
}

#pragma mark -
#pragma mark Comparison

-(BOOL)isEqualWithPeerID:(NSString *)peerID;
{
	return ([_peerID isEqual:peerID]);
}

-(BOOL)isEqualWithPeerConnection:(id)peerConnection
{
	return ([_peerConnection isEqual:peerConnection]);
}

#pragma mark -
#pragma mark Connection Returns

-(GCDAsyncSocket *)socket
{
	return _peerConnection;
}

-(GKSession *)session
{
	return _peerConnection;
}

@end
