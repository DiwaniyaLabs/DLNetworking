//
//  DLNetworkingSockets.m
//  Diwaniya Network
//
//  Created by Sour on 6/16/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "DLNetworkingSockets.h"

@implementation DLNetworkingSockets (Helpers)

#pragma mark -
#pragma mark Helper methods

-(void)SockSendPacket:(NSData *)packet toPeer:(DLNetworkingPeer *)peer
{
	// get packet length
	NSUInteger length = packet.length;
	NSData *packetLength = [NSData dataWithBytes:&length length:4];
	
	// first, send length of the packet
	[peer.socket writeData:packetLength withTimeout:-1 tag:0];
	
	// then, send the packet itself
	[peer.socket writeData:packet withTimeout:-1 tag:1];
}

@end

@implementation DLNetworkingSockets

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate withPort:(uint16_t)port
{
	if ( (self = [super initWithDelegate:delegate]) )
	{
		// save the port we're planning to broadcast/listen on
		_port = port;
		
		// set the protocol
		protocol = DLProtocolSockets;
	}
	
	return self;
}

-(void)removeAllDelegates
{
	if (currentPeer)
		currentPeer.socket.delegate = nil;
	
	for (DLNetworkingPeer *peer in networkingPeers)
		peer.socket.delegate = nil;
}

#pragma mark -
#pragma mark Peer Setup

-(BOOL)startListening
{
	// if the object already exists, return an error
	if (currentPeer)
	{
		NSLog(@"DLNetworking failed to listen. Instance already initialized.");
		return NO;
	}
	
	// create server socket
	GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// create peer
	currentPeer = [DLNetworkingPeer peerWithConnection:socket];
	
	// start listening
	NSError *error;
	if (![currentPeer.socket acceptOnPort:_port error:&error])
	{
		NSLog(@"DLNetworking failed to start listening on port %i. Reason: %@", _port, error.localizedFailureReason);
		
		return NO;
	}
	
	return [super startListening];
}

-(void)stopListening
{
	// not even a server?
	if (!isInitializedForListening)
	{
		NSLog(@"DLNetworking can not stop listening since it is not a server.");
		return;
	}
	
	// not even listening?
	if (!currentPeer)
	{
		NSLog(@"DLNetworking does not have an initialized server instance yet. Please call startListening first.");
		return;
	}
	
	// not sure this will work, but let's give it a shot	
	[currentPeer.socket disconnect];
	
	// remove
	currentPeer = nil;
	
	[super stopListening];
}

-(BOOL)startDiscovering
{
	NSLog(@"DLNetworking does not support discovering via sockets.");
	return NO;
}

-(void)stopDiscovering
{
	NSLog(@"DLNetworking does not support discovering via sockets.");
}

#pragma mark -
#pragma mark Peer Connectivity

-(BOOL)connectToPeer:(NSString *)hostName
{
	// server trying to connect? NO!
	if (isListening)
	{
		NSLog(@"DLNetworking can not connect to a host if it's listening for connections.");
		return NO;
	}
	
	// already connected?
	if (isConnected)
	{
		NSLog(@"DLNetworking instance is already connected to a host.");
		return NO;
	}
	
	// create client socket
	GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// create peer
	currentPeer = [DLNetworkingPeer peerWithConnection:socket];
	
	NSError *error;
	
	// attempt to connect
	if (![currentPeer.socket connectToHost:hostName onPort:_port withTimeout:5 error:&error])
	{
		// connect failed
		NSLog(@"DLNetworking failed to connect to host %@. Reason: %@", hostName, error.localizedFailureReason);
		
		return NO;
	}
	
	return YES;
}

-(void)disconnect
{
	// if we're serving hosts, disconnect them all
	if (isInitializedForListening)
	{
		// disconnect all peers
		for (DLNetworkingPeer *peer in networkingPeers)
			[self disconnectPeer:peer];
		
		// as well as server
		[self disconnectPeer:currentPeer];
	}
	// if we're a client, just disconnect from the server
	else
	{
		// disconnect from server
		[self disconnectPeer:currentPeer];
	}
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	// disconnect
	[peer.socket disconnect];
}

#pragma mark -
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	[self SockSendPacket:packet toPeer:peer];
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	for (DLNetworkingPeer *curPeer in peers)
		[self SockSendPacket:packet toPeer:curPeer];
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	for (DLNetworkingPeer *curPeer in peers)
		if (curPeer != peer)
			[self SockSendPacket:packet toPeer:curPeer];
}

-(void)sendToAll:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	for (DLNetworkingPeer *curPeer in networkingPeers)
		[self SockSendPacket:packet toPeer:curPeer];
}

-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	// send the packet
	for (DLNetworkingPeer *curPeer in networkingPeers)
		if (curPeer != peer)
			[self SockSendPacket:packet toPeer:peer];
}

-(void)sendToServer:(char)packetType, ...
{
	// get packet
	va_list args;
	va_start(args, packetType);
	NSData *packet = [self createPacket:packetType withList:args];
	va_end(args);
	
	if (!isInitializedForListening && isConnected)
		[self SockSendPacket:packet toPeer:currentPeer];
}

#pragma mark -
#pragma mark GCDAsyncSocket generic

-(void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
	// length tag
	if (tag == 0)
	{
		// get number of bytes to read
		unsigned int lengthToRead;
		[data getBytes:&lengthToRead length:4];
		
		// request NSData
		[sender readDataToLength:lengthToRead withTimeout:-1 tag:1];
	}
	// NSData tag
	else
	{
		DLNetworkingPeer *peer = [self peerFromConnectionID:sender];
		
		// notify delegate of this packet
		[SafeDelegateFromPeer(peer) networking:self didReceivePacket:data fromPeer:peer];
		
		// request length
		[sender readDataToLength:sizeof(unsigned int) withTimeout:-1 tag:0];
	}
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	if (isInitializedForListening)
	{
		// disconnected peer handler
		DLNetworkingPeer *peer = [self peerFromConnectionID:sock];
		
		// if it didn't exist, then the server got disconnected - IGNORE THIS
		if (![self removePeerWithConnectionID:sock])
			return;
		
		// we're no longer connected
		if (networkingPeers.count == 0)
			isConnected = NO;
		
		// notify delegate
		[SafeDelegateFromPeer(peer) networking:self didDisconnectPeer:peer withError:nil];
	}
	else
	{ 
		// we're no longer connected
		isConnected = NO;
		 
		// notify delegate
		[_delegate networking:self didDisconnectWithError:[self createErrorWithCode:err.code]];
	}
}
		 
#pragma mark -
#pragma mark GCDAsyncSocket server-specific
 
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	// get the host's name
	NSString *peerID = [newSocket connectedHost];
	
	// see if we have any peers with this peer ID
	DLNetworkingPeer *peer = [self peerFromPeerID:peerID];
	
	// if we do have one, then the user re-connected?
	if (peer)
	{
		NSLog(@"DLNetworking server already has the peer (%@) connected. Disconnecting previous instance.", peerID);
		
		// remove this peer...
		// NOTE: this line has been replaced so that removing the old peer will call the delegate's disconnect method
		[self disconnectPeer:peer];
		//		[networkingPeers removeObject:peer];
	}
	
	// create networking peer
	peer = [DLNetworkingPeer peerWithConnection:newSocket];
	
	// set its peer ID
	peer.peerID = peerID;
	
	// add it to our peers array
	[networkingPeers addObject:peer];
	
	// read packet stream from this peer
	[newSocket readDataToLength:sizeof(unsigned int) withTimeout:-1 tag:0];
	
	// set flag to connected
	isConnected = YES;
	
	// notify delegate
	[_delegate networking:self didConnectToPeer:peer];
}

#pragma mark -
#pragma mark GCDAsyncSocket client-specific

-(void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
	// set the peer's id
	currentPeer.peerID = host;
	
	// read packet stream from the server
	[sender readDataToLength:sizeof(unsigned int) withTimeout:-1 tag:0];
	
	// set flag to connected
	isConnected = YES;
	
	// notify delegate
	[_delegate networking:self didConnectToServer:currentPeer];
}
 
@end
