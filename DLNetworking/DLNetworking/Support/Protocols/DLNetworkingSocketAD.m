//
//  DLNetworkingSocketAD.m
//  iSibeeta
//
//  Created by Mansour Alsarraf on 7/31/12.
//
//

#import "DLNetworkingSocketAD.h"

#import "DLNetworkingDummyClient.h"
#import "DLNetworkingPeerDummy.h"

@implementation DLNetworkingSocketAD

#pragma mark -
#pragma mark Peer Connectivity

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	// if this peer is a dummy
	if (peer.isDummy)
	{
		// get peer
		peer = [self peerFromPeerID:peer.peerID];
		
		// disconnect this instance
		[self socketDidDisconnect:(GCDAsyncSocket *)peer withError:nil];
		
		// disconnect server instance
		[[(DLNetworkingPeerDummy *)peer dummyInstance] instanceDidDisconnect:peer];
		
		return;
	}
	
	[super disconnectPeer:peer];
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(void)SockSendPacket:(NSData *)packet toPeer:(DLNetworkingPeer *)peer
{
	// if it's a dummy client
	if (peer.isDummy)
	{
		// get the peer
		peer = [self peerFromPeerID:peer.peerID];
		
		// tell it currentPeer says hi
		[[(DLNetworkingPeerDummy *)peer dummyInstance] instanceDidReceivePacket:packet fromPeer:peer];
		
		return;
	}
	
	[super SockSendPacket:packet toPeer:peer];
}

#pragma mark -
#pragma mark GCDAsyncSocket generic

-(void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
	if (tag == 1)
	{
		DLNetworkingPeerDummy *peer = [sender isKindOfClass:[DLNetworkingPeerDummy class]] ? peer : nil;
		
		// notify delegate of this packet
		[SafeDelegateFromPeer(peer) networking:self didReceivePacket:data fromPeer:peer];
		
		return;
	}
	
	[super socket:sender didReadData:data withTag:tag];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	DLNetworkingPeerDummy *peer = [sock isKindOfClass:[DLNetworkingPeerDummy class]] ? peer : nil;
	
	if (peer)
	{
		// remove peer
		[self removePeer:peer];
		
		// notify delegate
		[SafeDelegateFromPeer(peer) networking:self didDisconnectPeer:peer withError:nil];
		
		return;
	}
	
	[super socketDidDisconnect:sock withError:err];
}

#pragma mark -
#pragma mark GCDAsyncSocket server-specific

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	if ([newSocket isKindOfClass:[DLNetworkingPeerDummy class]])
	{
		DLNetworkingPeerDummy *peerDummy = (DLNetworkingPeerDummy *)newSocket;
		
		// create new peer
		DLNetworkingPeerDummy *peer = [DLNetworkingPeerDummy peerWithDummyInstance:peerDummy.dummyInstance andServerInstance:peerDummy.serverInstance];
		
		// add it
		[self addPeer:peer];
		
		// notify dummy instance first
		[peer.dummyInstance instanceDidConnectToPeer:peer];
		
		// notify delegate
		[_delegate networking:self didConnectToPeer:peer];
		
		return;
	}
	
	[super socket:sock didAcceptNewSocket:newSocket];
}

@end
