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

#pragma mark -
#pragma mark Packets

#define PacketStart(data)					NSArray *packetArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#define PacketHeader()						[[packetArray objectAtIndex:0] charValue]
#define PacketArray							packetArray

#define Int(integerValue)					[NSNumber numberWithInt:integerValue]
#define Int16(shortValue)					[NSNumber numberWithUnsignedShort:shortValue]
#define Float(floatValue)					[NSNumber numberWithFloat:floatValue]
#define Boolean(boolValue)					[NSNumber numberWithBool:boolValue]
#define Struct(value)						[NSData dataWithBytes:&value length:sizeof(value)]

#define GetInt(index)						[[packetArray objectAtIndex:index] intValue]
#define GetInt16(index)						[[packetArray objectAtIndex:index] unsignedShortValue]
#define GetFloat(index)						[[packetArray objectAtIndex:index] floatValue]
#define GetBoolean(index)						[[packetArray objectAtIndex:index] boolValue]
#define GetStruct(index, receiver)			[[packetArray objectAtIndex:index] getBytes:&receiver length:sizeof(receiver)]

#define GetObject(index)					[packetArray objectAtIndex:index]

typedef enum
{
	DLNetworkingErrorNotOnline			= 65,	// socket error
	DLNetworkingErrorConnectionRefused	= 61,	// socket error
	DLNetworkingErrorConnectionClosed	= 7,	// socket error
	DLNetworkingErrorConnectionTimedOut	= 3,	// socket error
	DLNetworkingErrorUnknown			= -1,	// custom error
}	DLNetworkingError;

@protocol DLNetworkingDelegate <NSObject>
@required
// called upon receiving a packet from a peer
-(void)networking:(DLNetworking *)networking didReceivePacket:(NSData *)packet fromPeer:(DLNetworkingPeer *)peer;
@end

@protocol DLNetworkingClientDelegate <DLNetworkingDelegate>
@optional
// called upon discovering new peers to which we can connect
-(void)networking:(DLNetworking *)networking didDiscoverPeers:(NSArray *)peers;
@required
// called upon successful connection to the server
-(void)networking:(DLNetworking *)networking didConnectToServer:(DLNetworkingPeer *)peer;
// called upon disconnection from the peer
-(void)networking:(DLNetworking *)networking didDisconnectWithError:(NSError *)error;
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
	DLProtocolDummyClient,
	DLProtocolSocket,
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	DLProtocolGameKit,
#endif
}	DLProtocol;

@interface DLNetworking : NSObject
{
	// the current protocol being used
	DLProtocol protocol;
	
	iweak id<DLNetworkingClientDelegate,DLNetworkingServerDelegate> _delegate;
	
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

// initializes a local instance server/client
+(DLNetworking *)networkingViaDummyClient:(id<DLNetworkingDelegate>)delegate;

// initializes a socket server/client
+(DLNetworking *)networkingViaSocket:(id<DLNetworkingDelegate>)delegate withPort:(uint16_t)port allowDummies:(BOOL)allowDummies;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
// initializes a GameKit server/client
+(DLNetworking *)networkingViaGameKit:(id<DLNetworkingDelegate>)delegate withSessionID:(NSString *)sessionID allowDummies:(BOOL)allowDummies;
#endif

// initializes an instance of DLNetworking
-(id)initWithDelegate:(id)delegate;

// sets the delegate for a specific peer
// NOTE: this only relays disconnects and packets
-(void)setDelegate:(id<DLNetworkingDelegate>)delegate forPeer:(DLNetworkingPeer *)peer;

// sets the delegate for all current peers and new peers
-(void)setDelegateForAllPeers:(id<DLNetworkingDelegate>)delegate;

// remove all delegates
-(void)removeAllInnerDelegates;

#pragma mark -
#pragma mark DLNetworkingPeer

// finds the peer object by peerID
-(DLNetworkingPeer *)peerFromPeerID:(NSString *)peerID;

// finds the peer object by connectionID
-(DLNetworkingPeer *)peerFromConnectionID:(id)connectionID;

#pragma mark -
#pragma mark Networking Setup

// start broadcasting as a server
-(BOOL)startListening;

// stop broadcasting as a server
-(void)stopListening;

// start discovering peers
-(BOOL)startDiscovering;

// stop discovering peers
-(void)stopDiscovering;

#pragma mark -
#pragma mark Peer Events

// add a peer to the networking instance
-(void)addPeer:(DLNetworkingPeer *)peer;

// remove a peer from the networking instance
-(void)removePeer:(DLNetworkingPeer *)peer;

#pragma mark -
#pragma mark Peer Connectivity

// connect to an instance
-(BOOL)connectToInstance:(DLNetworking *)instance;

// connect to a server
-(BOOL)connectToServer:(id)peer;

// stop connecting
-(void)cancelConnectToServer;

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

#pragma mark -
#pragma mark Error Construction

// creates an NSError object that describes the error
-(NSError *)createErrorWithCode:(DLNetworkingError)errorCode;

@end
