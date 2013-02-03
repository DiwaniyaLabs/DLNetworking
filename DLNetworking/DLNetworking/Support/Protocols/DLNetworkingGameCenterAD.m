//
// Created by Sour on 1/31/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <GameKit/GameKit.h>
#import "DLNetworkingGameCenterAD.h"
#import "DLNetworkingPeerDummy.h"
#import "DLNetworkingDummyClient.h"


@implementation DLNetworkingGameCenterAD

-(void)removeAllInnerDelegates
{
	[super removeAllInnerDelegates];

	for (DLNetworkingPeerDummy *peer in networkingPeers)
	{
		if (peer.isDummy)
		{
			peer.dummyInstance = nil;
			peer.serverInstance = nil;
		}
	}
}

-(void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
	// dummy?
	if (match == nil)
	{
		DLNetworkingPeerDummy *peer = (id)playerID;

		if (state == GKPlayerStateConnected)
		{
			// create new peer
			DLNetworkingPeerDummy *peerNew = [DLNetworkingPeerDummy peerWithDelegate:_delegate dummyInstance:peer.dummyInstance serverInstance:peer.serverInstance];

			// add it
			[self addPeer:peerNew];

			// notify dummy instance first
			[peer.dummyInstance instanceDidConnectToPeer:peerNew];

			// notify delegate
			[_delegate networking:self didConnectToPeer:peerNew];
		}
	}
	else
		[super match:match player:playerID didChangeState:state];
}

-(void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
	// dummy?
	if (match == nil)
	{
		DLNetworkingPeerDummy *peer = (id)playerID;
		peer = (id)[self peerFromPeerID:peer.peerID];
		[peer.delegate networking:self didReceivePacket:data fromPeer:peer];
	}
	else
		[super match:match didReceiveData:data fromPlayer:playerID];
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(NSArray *)playerIDsFromPeers:(NSArray *)peers andSendDummiesPacket:(id)packet
{
	NSMutableArray *playerIDs = [NSMutableArray arrayWithCapacity:peers.count];
	
	for (DLNetworkingPeerDummy *peer in peers)
	{
		if (peer.isDummy)
			[peer.dummyInstance instanceDidReceivePacket:packet fromPeer:currentPeer];
		else
			[playerIDs addObject:peer.peerID];
	}
	
	return playerIDs;
}

-(void)GCSendToPeers:(NSArray *)peers packet:(id)packet
{
	// send the packet through game center
	id playerIDs = [self playerIDsFromPeers:peers andSendDummiesPacket:packet];
	[_match sendData:packet toPlayers:playerIDs withDataMode:GKMatchSendDataReliable error:nil];
}

-(void)GCSendToAllPeers:(id)packet
{
	// send the packet through game center
	[self playerIDsFromPeers:networkingPeers andSendDummiesPacket:packet];

	// default process
	[super GCSendToAllPeers:packet];
}

@end