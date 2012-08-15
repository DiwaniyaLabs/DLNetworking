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

@protocol DLNetworkingDelegate;

@interface DLNetworkingPeer : NSObject
{
	// the peer's name
	NSString *_peerName;
	
	// the peer's unique ID
	NSString *_peerID;
	
	// the peer's connection handler
	id _peerConnection;
	
	// custom delegate
	iweak id _delegate;
	
	// user data associated with this particular player
	NSMutableDictionary *_userObjects;
	
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
+(DLNetworkingPeer *)peerWithDelegate:(id<DLNetworkingDelegate>)delegate connection:(id)connection peerID:(NSString *)peerID name:(NSString *)name;

// initializes peer
-(id)initWithDelegate:(id<DLNetworkingDelegate>)delegate connection:(id)connection peerID:(NSString *)peerID name:(NSString *)name;

#pragma mark -
#pragma mark User Data

// sets an object under the given key name
-(void)setUserValue:(id)value forKey:(NSString *)key;

// gets object previously associated with key name
-(id)userValueForKey:(NSString *)key;

#pragma mark -
#pragma mark Comparison

// compares DLNetworkPeer's peerIDs
-(BOOL)isEqualWithPeerID:(NSString *)peerID;

// compares DLNetworkPeer's peerConnections
-(BOOL)isEqualWithPeerConnection:(id)peerConnection;

#pragma mark -
#pragma mark Connection Returns

// returns the peerConnection object as a GCDAsyncSocket
-(GCDAsyncSocket *)socket;

// returns the peerConnection object as a GKSession
-(GKSession *)session;

@end
