//
//  DLNetworkingDummyClient.m
//  DLNetworking
//
//  Created by Mansour Alsarraf on 7/30/12.
//
//

#import "DLNetworkingDummyClient.h"

#import "DLNetworkingSocketAD.h"
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import "DLNetworkingGameKitAD.h"
#endif

// import dummy peer
#import "DLNetworkingPeerDummy.h"
#import "DLNetworkingGameCenter.h"

@implementation DLNetworkingDummyClient

@synthesize instanceID;

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate
{
	if ( (self = [super initWithDelegate:delegate]) )
	{
		// set the instanceID to the memory location, as a unique identifier for this instance
		instanceID = [NSString stringWithFormat:@"DummyClient_%p", self];

		// set the protocol
		protocol = DLProtocolDummyClient;
	}
	
	return self;
}

-(void)removeAllInnerDelegates
{
	((DLNetworkingPeerDummy *)currentPeer).dummyInstance = nil;
	((DLNetworkingPeerDummy *)currentPeer).serverInstance = nil;
}

#pragma mark -
#pragma mark Peer Setup

-(BOOL)startListening
{
	NSLog(@"DLNetworking does not support listening for connections as a dummy client.");
	return NO;
}

-(void)stopListening
{
	return;
}

-(BOOL)startDiscovering
{
	NSLog(@"DLNetworking does not support discovering peers as a dummy client.");
	return NO;
}

-(void)stopDiscovering
{
	return;
}

#pragma mark -
#pragma mark Peer Connectivity

-(BOOL)connectToInstance:(DLNetworking *)instance
{
	// create the peer we're going to be using
	DLNetworkingPeer *peer = [DLNetworkingPeerDummy peerWithDelegate:_delegate dummyInstance:self serverInstance:instance];
	
	return [self connectToServer:peer];
}

-(BOOL)connectToServer:(DLNetworkingPeer *)peer
{
	if (isInitializedForListening)
	{
		NSLog(@"DLNetworkingDummyClient could not connect to peer while listening.");
		return NO;
	}
	
	// tell the server we've connected
	DLNetworking *server = [(DLNetworkingPeerDummy *)peer serverInstance];
	switch (server.protocol)
	{
		case DLProtocolDummyClient:
			NSLog(@"DLNetworking can not connect to a dummy client via dummy client.");
			return YES;
		case DLProtocolSocket:
			[(DLNetworkingSocket *)server socket:nil didAcceptNewSocket:(GCDAsyncSocket *)peer];
			return YES;
		case DLProtocolGameCenter:
			[(DLNetworkingGameCenter *)server match:nil player:(id)peer didChangeState:GKPlayerStateConnected];
			return YES;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		case DLProtocolGameKit:
			[(DLNetworkingGameKit *)server session:(GKSession *)peer peer:instanceID didChangeState:GKPeerStateConnected];
			return YES;
		#endif
		default:
			return NO;
	}
}

-(void)disconnect
{
	DLNetworkingPeerDummy *peer = (DLNetworkingPeerDummy *)currentPeer;
	
	// notify the server
	if (peer.serverInstance)
	{
		[self disconnectInstance:peer.serverInstance];
	}
	
	// also notify client (self)
	if (peer.dummyInstance == self)
	{
		[self instanceDidDisconnect:currentPeer];
	}
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	NSLog(@"DLNetworking can not disconnect peer from this dummy client.");
}

-(void)disconnectInstance:(DLNetworking *)instance
{
	switch (instance.protocol)
	{
		case DLProtocolDummyClient:
			NSLog(@"DLNetworking can not disconnect from a dummy client.");
			break;
		case DLProtocolSocket:
			[(DLNetworkingSocket *)instance socketDidDisconnect:(GCDAsyncSocket *)currentPeer withError:nil];
			break;
		case DLProtocolGameCenter:
			[(DLNetworkingGameCenter *)instance match:nil player:(id)currentPeer didChangeState:GKPlayerStateDisconnected];
			break;
		#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		case DLProtocolGameKit:
			[(DLNetworkingGameKit *)instance session:(GKSession *)currentPeer peer:instanceID didChangeState:GKPeerStateDisconnected];
			break;
		#endif
	}
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(void)instanceSendPacket:(NSData *)packet toPeer:(DLNetworkingPeer *)peer
{
	DLNetworking *serverInstance = [(DLNetworkingPeerDummy *)peer serverInstance];
	
	// figure out which protocol it's in
	switch (serverInstance.protocol)
	{
		case DLProtocolDummyClient:
			NSLog(@"DLNetworking can not send packet to dummy client as dummy client.");
			break;
		case DLProtocolSocket:
			[(DLNetworkingSocket *)serverInstance socket:(GCDAsyncSocket *)peer didReadData:packet withTag:1];
			break;
		case DLProtocolGameCenter:
			[(DLNetworkingGameCenter *)serverInstance match:nil didReceiveData:packet fromPlayer:(id)peer];
			break;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		case DLProtocolGameKit:
			[(DLNetworkingGameKit *)serverInstance receiveData:packet fromPeer:instanceID inSession:(GKSession *)peer context:nil];
			break;
#endif
	}
}

#pragma mark -
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	NSLog(@"DLNetworking does not support sending packets to a client via dummy client.");
	return;
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	NSLog(@"DLNetworking does not support sending packets to a client via dummy client.");
	return;
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	NSLog(@"DLNetworking does not support sending packets to a client via dummy client.");
	return;
}

-(void)sendToAll:(char)packetType, ...
{
	NSLog(@"DLNetworking does not support sending packets to a client via dummy client.");
	return;
}

-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	NSLog(@"DLNetworking does not support sending packets to a client via dummy client.");
	return;
}

-(void)sendToServer:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	[self instanceSendPacket:packet toPeer:currentPeer];
}

#pragma mark -
#pragma mark Local Instance generic

-(void)instanceDidDisconnect:(DLNetworkingPeer *)peer
{
	// double-disconnect failsafe
	if (![currentPeer.peerID isEqualToString:peer.peerID])
		return;
	
	// notify delegate
	[currentPeer.delegate networking:self didDisconnectWithError:[self createErrorWithCode:DLNetworkingErrorConnectionClosed]];
	
	currentPeer = nil;
	isConnected = NO;
}

-(void)instanceDidReceivePacket:(NSData *)packet fromPeer:(DLNetworkingPeer *)peer
{
	[currentPeer.delegate networking:self didReceivePacket:packet fromPeer:peer];
}

#pragma mark -
#pragma mark Local Instance client-specific

-(void)instanceDidConnectToPeer:(DLNetworkingPeerDummy *)peer
{
	// only do this for non-server instances
	if (isInitializedForListening)
		return;
	
	// save the peer
	currentPeer = [DLNetworkingPeerDummy peerWithDelegate:_delegate dummyInstance:peer.dummyInstance serverInstance:peer.serverInstance];
	
	// set to connected
	isConnected = YES;
	
	// notify delegate
	[_delegate networking:self didConnectToServer:peer];
}

@end
