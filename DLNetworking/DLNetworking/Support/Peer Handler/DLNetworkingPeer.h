//
//  DLNetworkingPeer.h
//  Diwaniya Client
//
//  Created by Sour on 6/17/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@class GKSession;

@interface DLNetworkingPeer : NSObject
{
	// the peer's name
	NSString *peerName;
	
	// the peer's unique ID
	NSString *peerID;
	
	// the peer's connection handler
	id peerConnection;
	
	// custom delegate
	iweak id delegate;
	
	// user data associated with this particular player
	NSMutableDictionary *userObjects;
	
	// yes if this is a dummy client
	BOOL _isDummy;
}

@property (nonatomic, strong) NSString *peerName;
@property (nonatomic, strong) NSString *peerID;
@property (nonatomic, pweak) id delegate;
@property (nonatomic, strong) id<NSObject> peerConnection;
@property (nonatomic, readonly) BOOL isDummy;

#pragma mark -
#pragma mark Initialization

// creates a new peer
+(DLNetworkingPeer *)peerWithConnection:(id)_peerConnection;

// creates a new peer
+(DLNetworkingPeer *)peerWithConnection:(id)_peerConnection andPeerID:(NSString *)_peerID andName:(NSString *)_peerName;

// initializes a new peer
-(id)initWithPeerConnection:(id<NSObject>)_peerConnection andPeerID:(NSString *)_peerID andName:(NSString *)_peerName;

#pragma mark -
#pragma mark User Data

// sets an object under the given key name
-(void)setUserValue:(id)value forKey:(NSString *)key;

// gets object previously associated with key name
-(id)userValueForKey:(NSString *)key;

#pragma mark -
#pragma mark Comparison

// compares DLNetworkPeer's peerIDs
-(BOOL)isEqualWithPeerID:(NSString *)_peerID;

// compares DLNetworkPeer's peerConnections
-(BOOL)isEqualWithPeerConnection:(id)_peerConnection;

#pragma mark -
#pragma mark Connection Returns

// returns the peerConnection object as a GCDAsyncSocket
-(GCDAsyncSocket *)socket;

// returns the peerConnection object as a GKSession
-(GKSession *)session;

@end
