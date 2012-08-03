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
		protocol = DLProtocolGameKit;
	}
	
	return self;
}

-(void)dealloc
{
	if (isConnected)
		[self disconnect];
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
	// make sure the instance is indeed listening
	if (!instance.isListening ||
		(![instance isKindOfClass:[DLNetworkingGameKitAD class]] &&
		![instance isKindOfClass:[DLNetworkingSocketAD class]]))
		return NO;
	
	// create the peer we're going to be using
	DLNetworkingPeer *peer = [DLNetworkingPeerDummy peerWithDummyInstance:self andServerInstance:instance];
	
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
	// tell the server/client we've disconnected
	DLNetworking *serverInstance = [(DLNetworkingPeerDummy *)currentPeer serverInstance];
	switch (serverInstance.protocol)
	{
		case DLProtocolDummyClient:
			NSLog(@"DLNetworking can not disconnect from a dummy client.");
			break;
		case DLProtocolSocket:
			[(DLNetworkingSocket *)serverInstance socketDidDisconnect:(GCDAsyncSocket *)currentPeer withError:nil];
			break;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		case DLProtocolGameKit:
			[(DLNetworkingGameKit *)serverInstance session:(GKSession *)currentPeer peer:instanceID didChangeState:GKPeerStateDisconnected];
			break;
#endif
	}
	
	// also notify self about the disconnection
	[self instanceDidDisconnect:currentPeer];
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	NSLog(@"DLNetworking can not disconnect peer from this dummy client.");
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
	// notify delegate
	[SafeDelegateFromPeer(currentPeer) networking:self didDisconnectWithError:[self createErrorWithCode:DLNetworkingErrorConnectionClosed]];
	
	currentPeer = nil;
	isConnected = NO;
}

-(void)instanceDidReceivePacket:(NSData *)packet fromPeer:(DLNetworkingPeer *)peer
{
	[SafeDelegateFromPeer(currentPeer) networking:self didReceivePacket:packet fromPeer:peer];
}

#pragma mark -
#pragma mark Local Instance client-specific

-(void)instanceDidConnectToPeer:(DLNetworkingPeerDummy *)peer
{
	// only do this for non-server instances
	if (isInitializedForListening)
		return;
	
	// save the peer
	currentPeer = [DLNetworkingPeerDummy peerWithDummyInstance:peer.dummyInstance andServerInstance:peer.serverInstance];
	
	// set to connected
	isConnected = YES;
	
	// notify delegate
	[_delegate networking:self didConnectToServer:peer];
}

@end
