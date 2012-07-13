//
//  DLNetworking.h
//  Diwaniya Network
//
//  Created by Sour on 6/16/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DLNetworkingPeer.h"

@class DLNetworking;

#define SafeDelegateFromPeer(peer)			(peer.delegate != nil) ? peer.delegate : _delegate

#pragma mark -
#pragma mark Packets

#define PacketHeaderFromArray(array)		[[array objectAtIndex:0] charValue]

#define Int(integerValue)					[NSNumber numberWithInt:integerValue]
#define Int16(shortValue)					[NSNumber numberWithUnsignedShort:shortValue]
#define Struct(value)						[NSData dataWithBytes:&value length:sizeof(value)]

#define GetInt(array, index)				[[array objectAtIndex:index] intValue]
#define GetInt16(array, index)				[[array objectAtIndex:index] unsignedShortValue]
#define GetStruct(array, index, receiver)	[[array objectAtIndex:index] getBytes:&receiver length:sizeof(receiver)]

#define GetObject(array, index)				[array objectAtIndex:index]

typedef enum
{
	DLNetworkingErrorNotOnline			= 65,
	DLNetworkingErrorConnectionRefused	= 61,
	DLNetworkingErrorConnectionClosed	= 7,
	DLNetworkingErrorConnectionTimedOut	= 3,
}	DLNetworkingError;

@protocol DLNetworkingDelegate <NSObject>
@required
// called upon receiving a packet from a peer
-(void)networking:(DLNetworking *)networking didReceivePacket:(NSData *)packet fromPeer:(DLNetworkingPeer *)peer;
@end

@protocol DLNetworkingClientDelegate <DLNetworkingDelegate>
@required
// called upon successful connection to the server
-(void)networking:(DLNetworking *)networking didConnectToServer:(DLNetworkingPeer *)peer;
// called upon disconnection from the peer
-(void)networking:(DLNetworking *)networking didDisconnectWithError:(NSError *)error;
@optional
// called upon discovering new peers to which we can connect
-(void)networking:(DLNetworking *)networking didDiscoverPeers:(NSArray *)peers;
@end

@protocol DLNetworkingServerDelegate <DLNetworkingDelegate>
@required
// called when a client connects to the server.
-(void)networking:(DLNetworking *)networking didConnectToPeer:(DLNetworkingPeer *)peer;
// called upon disconnection from the peer
-(void)networking:(DLNetworking *)networking didDisconnectPeer:(DLNetworkingPeer *)peer withError:(NSError *)error;
@end

// connection types
typedef enum
{
	DLProtocolSockets,
	DLProtocolGameKit,
}	DLProtocol;

@interface DLNetworking : NSObject
{
	// the current protocol being used
	DLProtocol protocol;
	
	__unsafe_unretained id<DLNetworkingClientDelegate,DLNetworkingServerDelegate> _delegate;
	
	// current peer
	DLNetworkingPeer *currentPeer;
	
	// connected peers
	NSMutableArray *networkingPeers;
	
	// discovered peers
	NSMutableArray *discoveredPeers;
	
	// yes if we're connected to a server or a client
	BOOL isConnected;
	
	// whether the server was initialized for listening/discovering
	BOOL isInitializedForListening;
	BOOL isInitializedForDiscovering;
	
	// whether the server is listening/discovering
	BOOL isListening;
	BOOL isDiscovering;
}

@property (nonatomic) DLProtocol protocol;

@property (nonatomic, readonly) DLNetworkingPeer *currentPeer;

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isInitializedForListening;
@property (nonatomic, readonly) BOOL isInitializedForDiscovering;
@property (nonatomic, readonly) BOOL isListening;
@property (nonatomic, readonly) BOOL isDiscovering;

#pragma mark -
#pragma mark Initialization

// returns the available shared networking
// NOTE: Must call useNetworkingViaSocket or useNetworkingViaGameKit first!
+(DLNetworking *)sharedNetworking;

// stops all network activity and releases the object
+(void)end;

// initializes a socket server/client
+(void)useNetworkingViaSockets:(id<DLNetworkingDelegate>)delegate withPort:(uint16_t)port;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
// initializes a GameKit server/client
+(void)useNetworkingViaGameKit:(id<DLNetworkingDelegate>)delegate withSessionID:(NSString *)sessionID;
#endif

// initializes an instance of DLNetworking
-(id)initWithDelegate:(id)delegate;

// sets the delegate
-(void)setDelegate:(id<DLNetworkingDelegate>)delegate;

// sets the delegate for a specific peer
// NOTE: this only relays disconnects and packets
-(void)setDelegate:(id<DLNetworkingDelegate>)delegate forPeer:(DLNetworkingPeer *)peer;

// remove all delegates
-(void)removeAllDelegates;

#pragma mark -
#pragma mark DLNetworkingPeer

// removes the peer with matching peerID
-(BOOL)removePeerWithPeerID:(NSString *)peerID;

// removes the peer with matching connectionID
-(BOOL)removePeerWithConnectionID:(id)connectionID;

// finds the peer object by peerID
-(DLNetworkingPeer *)peerFromPeerID:(NSString *)peerID;

// finds the peer object by connectionID
-(DLNetworkingPeer *)peerFromConnectionID:(id)connectionID;

#pragma mark -
#pragma mark Peer Setup

// start broadcasting as a server
-(BOOL)startListening;

// stop broadcasting as a server
-(void)stopListening;

// start discovering peers
-(BOOL)startDiscovering;

// stop discovering peers
-(void)stopDiscovering;

#pragma mark -
#pragma mark Peer Connectivity

// connect to a server
-(BOOL)connectToPeer:(id)peer;

// disconnects the client or the server
-(void)disconnect;

// disconnect a specific peer
-(void)disconnectPeer:(DLNetworkingPeer *)peer;

#pragma mark -
#pragma mark Peer Queries

// returns number of connected peers (including the server, when instance is client)
-(int)numberOfConnectedPeers;

// returns a list of connected peers (DLNetworkingPeer)
-(NSArray *)connectedPeers;

// returns a list of discovered peers (DLNetworkingPeer)
-(NSArray *)discoveredPeers;

#pragma mark -
#pragma mark Packet Transmission

// send a packet to a peer
-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

// send a packet to peers in an array
-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

// send a packet to peers in an array except the given peer
-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

// send a packet to all peers
-(void)sendToAll:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

// send a packet to all peers except
-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

// send a packet to the server
-(void)sendToServer:(char)packetType, ... NS_REQUIRES_NIL_TERMINATION;

#pragma mark -
#pragma mark Packet Construction

// creates a packet using the given data into an NSData
-(NSData *)createPacket:(char)packetType withList:(va_list)args;

@end

__strong DLNetworking *_sharedNetworking;
extern __strong DLNetworking *_sharedNetworking;
