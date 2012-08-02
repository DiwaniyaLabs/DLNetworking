//
//  DLNetworkingGameKitAD.m
//  iSibeeta
//
//  Created by Mansour Alsarraf on 7/31/12.
//
//

#import "DLNetworkingGameKitAD.h"

#import "DLNetworkingDummyClient.h"
#import "DLNetworkingPeerDummy.h"

@implementation DLNetworkingGameKitAD

#pragma mark -
#pragma mark Peer Connectivity

-(void)disconnect
{
	// if we have any dummy peers, disconnect them manually
	for (DLNetworkingPeer *peer in networkingPeers)
	{
		if (peer.isDummy)
			[self disconnectPeer:peer];
	}
	
	// disconnect from all other peers
	[super disconnect];
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	if (peer.isDummy)
	{
		// disconnect this instance
		[self session:nil peer:peer.peerID didChangeState:GKPeerStateDisconnected];
		
		// disconnect server instance
		[[(DLNetworkingPeerDummy *)peer dummyInstance] instanceDidDisconnect:nil];
	}
	else
	{
		[super disconnectPeer:peer];
	}
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(NSArray *)peerIDsAfterSendingDummyClientPacket:(NSData *)packet toPeers:(NSArray *)peers except:(DLNetworkingPeer *)peerException
{
	NSMutableArray *peerIDs = [[NSMutableArray alloc] initWithCapacity:peers.count];
	
	for (DLNetworkingPeer *peer in peers)
	{
		// skip the peer that matches the exception
		if (peer == peerException)
			continue;
		
		// if it's a dummy client
		if (peer.isDummy)
		{
			// tell it currentPeer says hi
			[[(DLNetworkingPeerDummy *)peer dummyInstance] instanceDidReceivePacket:packet fromPeer:peer];
		}
		// otherwise, add this peer's ID to the list of peers to send, for GameKit's convenience
		else
		{
			[peerIDs addObject:peer.peerID];
		}
	}
	
	return peerIDs;
}

-(void)GKSendPacket:(NSData *)packet toPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer
{
	// get the peerIDs from every peer except Local Instances, which will be dealt with by this method
	NSArray *peerIDs = [self peerIDsAfterSendingDummyClientPacket:packet toPeers:peers except:peer];
	
	// instead of calling super here and looping over the peers again, just send the packet to the peer ID list we already have
	NSError *error;
	[currentPeer.session sendData:packet toPeers:peerIDs withDataMode:GKSendDataReliable error:&error];
}

-(void)GKSendPacketToAll:(NSData *)packet
{
	// make sure to send any local instances
	for (DLNetworkingPeer *peer in networkingPeers)
		if (peer.isDummy)
			[[(DLNetworkingPeerDummy *)peer dummyInstance] instanceDidReceivePacket:packet fromPeer:currentPeer];
	
	[super GKSendPacketToAll:packet];
}

#pragma mark -
#pragma mark GKSessionDelegate

// CONNECT/DISCONNECT/DISCOVER
-(void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	// if we have a dummy client, create deal with it here
	if (isInitializedForListening && [session isKindOfClass:[DLNetworkingPeerDummy class]])
	{
		DLNetworkingPeerDummy *peerDummy = (DLNetworkingPeerDummy *)session;
		
		// only deal with it if we're accepting a connection
		if (state == GKPeerStateConnected)
		{
			// create a new one
			DLNetworkingPeerDummy *peer = [DLNetworkingPeerDummy peerWithDummyInstance:peerDummy.dummyInstance andServerInstance:peerDummy.serverInstance];
			
			// add it
			[self addPeer:peer];
			
			// notify dummy instance first
			[peer.dummyInstance instanceDidConnectToPeer:peer];
			
			// notify delegate
			[_delegate networking:self didConnectToPeer:peer];
			
			return;
		}
	}
	
	// in all other cases, call super
	[super session:session peer:peerID didChangeState:state];
}

@end
