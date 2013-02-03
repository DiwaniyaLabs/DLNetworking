//
// Created by Sour on 1/29/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <GameKit/GameKit.h>
#import "DLNetworkingGameCenter.h"

@implementation DLNetworkingGameCenter

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate withGKMatch:(GKMatch *)match
{
	if ( (self = [super initWithDelegate:delegate]))
	{
		// set the protocol
		protocol = DLProtocolGameCenter;

		// retain the match object
		_match = match;

		// set its delegate
		_match.delegate = self;

		// add the players who have already connected
		for (NSString *playerID in match.playerIDs)
		{
			DLNetworkingPeer *peer = [DLNetworkingPeer peerWithDelegate:delegate connection:nil peerID:playerID name:nil];
			[self addPeer:peer];
		}

		// if all players have connected, assign the server right away
		if (_match.expectedPlayerCount == 0)
			[self assignServer];
	}

	return self;
}

-(void)removeAllInnerDelegates
{
	[self disconnect];
}

#pragma mark -
#pragma mark Peer Setup

-(BOOL)startListening
{
	NSLog(@"DLNetworkingGameCenter does not implement startListening.");
	return NO;
}

-(void)stopListening
{
	NSLog(@"DLNetworkingGameCenter does not implement stopListening.");
}

-(BOOL)startDiscovering
{
	NSLog(@"DLNetworkingGameCenter does not implement startDiscovering.");
	return NO;
}

-(void)stopDiscovering
{
	NSLog(@"DLNetworkingGameCenter does not implement stopDiscovering.");
}

#pragma mark -
#pragma mark Peer Connectivity

-(BOOL)connectToInstance:(DLNetworking *)instance;
{
	NSLog(@"DLNetworkingGameCenter does not implement connectToInstance.");
	return NO;
}

-(BOOL)connectToServer:(DLNetworkingPeer *)peer
{
	NSLog(@"DLNetworkingGameCenter does not implement connectToServer.");
	return NO;
}

-(void)cancelConnectToServer
{
	NSLog(@"DLNetworkingGameCenter does not implement cancelConnectToServer.");
}

-(void)disconnect
{
	// just disconnect
	[_match disconnect];
	_match = nil;
}

-(void)disconnectPeer:(DLNetworkingPeer *)peer
{
	NSLog(@"DLNetworkingGameCenter does not implement disconnectPeer.");
}

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(NSArray *)playerIDsFromPeers:(NSArray *)peers
{
	NSMutableArray *playerIDs = [NSMutableArray arrayWithCapacity:peers.count];
	
	for (DLNetworkingPeer *peer in peers)
	{
		[playerIDs addObject:peer.peerID];
	}
	
	return playerIDs;
}

-(void)GCSendToPeers:(NSArray *)peers packet:(id)packet
{
	// send the packet through game center
	id playerIDs = [self playerIDsFromPeers:peers];
	[_match sendData:packet toPlayers:playerIDs withDataMode:GKMatchSendDataReliable error:nil];
}

-(void)GCSendToAllPeers:(id)packet
{
	// send the packet through game center
	[_match sendDataToAllPlayers:packet withDataMode:GKMatchSendDataReliable error:nil];
}

#pragma mark -
#pragma mark Packet Transmission

-(void)sendToPeer:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	id peers = [[NSArray alloc] initWithObjects:peer, nil];

	// send the packet
	[self GCSendToPeers:peers packet:packet];
}

-(void)sendToPeers:(NSArray *)peers packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	// send the packet
	[self GCSendToPeers:peers packet:packet];
}

-(void)sendToPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	// send the packet
	NSMutableArray *newPeers = [NSMutableArray arrayWithArray:peers];
	[newPeers removeObject:peer];
	[self GCSendToPeers:newPeers packet:packet];
}

-(void)sendToAll:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	// send the packet
	[self GCSendToAllPeers:packet];
}

-(void)sendToAllExcept:(DLNetworkingPeer *)peer packet:(char)packetType, ...
{
	// create the packet
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	// send packet
	NSMutableArray *newPeers = [NSMutableArray arrayWithArray:networkingPeers];
	[newPeers removeObject:peer];
	[self GCSendToPeers:newPeers packet:packet];
}

-(void)sendToServer:(char)packetType, ...
{
	va_list args;
	va_start(args, packetType);
	id packet = [self createPacket:packetType withList:args];
	va_end(args);

	id peers = [[NSArray alloc] initWithObjects:_peerServer, nil];

	// the server could only be a GK instance, not a local instance
	[self GCSendToPeers:peers packet:packet];
}

#pragma mark -
#pragma mark Server Assignment

-(void)assignServer
{
	// pick the server.. start with the first player
	NSString *localPlayerID = [GKLocalPlayer localPlayer].playerID;
	NSString *playerIDHighest = localPlayerID;

	// find another player that has a higher player ID
	for (NSString *pID in _match.playerIDs)
	{
		// compare our ID with the other player's ID
		NSComparisonResult result = [playerIDHighest compare:pID options:NSNumericSearch];

		// -1 means our current highest ID is lower, +1 means it's higher
		if (result == -1)
			playerIDHighest = pID;
	}

	// so we've decided on a server? make a peer that links to it
	_peerServer = [DLNetworkingPeer peerWithDelegate:_delegate connection:nil peerID:playerIDHighest name:nil];

	// set server bool
	_isServer = [playerIDHighest isEqualToString:[GKLocalPlayer localPlayer].playerID];

	// set connected
	isConnected = YES;

	// notify delegate
	if (_isServer)
	{
		currentPeer = _peerServer;

		for (NSString *pID in _match.playerIDs)
		{
			// notify delegate
			DLNetworkingPeer *peer = [DLNetworkingPeer peerWithDelegate:_delegate connection:nil peerID:pID name:nil];
			[self addPeer:peer];
			[_delegate networking:self didConnectToPeer:peer];
		}

		// set to listening, just because we kinda are
		isInitializedForListening = YES;
		isListening = YES;
	}
	else
	{
		// notify delegate
		currentPeer = [DLNetworkingPeer peerWithDelegate:_delegate connection:nil peerID:localPlayerID name:nil];
		[_delegate networking:self didConnectToServer:currentPeer];

		// set to not listening
		isInitializedForListening = NO;
		isListening = NO;
	}
}

#pragma mark -
#pragma mark GKMatchDelegate

-(void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
	DLNetworkingPeer *peer = [self peerFromPeerID:playerID];
	[peer.delegate networking:self didReceivePacket:data fromPeer:peer];
}

-(void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
	switch (state)
	{
		case GKPlayerStateConnected:
		{
			if (_isServer)
			{
				DLNetworkingPeer *peer = [DLNetworkingPeer peerWithDelegate:_delegate connection:nil peerID:playerID name:nil];
				[self addPeer:peer];
			}
			break;
		}
		case GKPlayerStateDisconnected:
		{
			// on the server, regular stuff
			if (_isServer)
			{
				// remove peer
				DLNetworkingPeer *peer = [self peerFromPeerID:playerID];
				[self removePeer:peer];

				// notify delegate
				[peer.delegate networking:self didDisconnectPeer:peer withError:nil];
			}
			// as a client, we're only really disconnected if the server disconnected
			else
			{
				if ([_peerServer isEqualWithPeerID:playerID])
				{
					// no need for peer anymore
					_peerServer = nil;

					[currentPeer.delegate networking:self didDisconnectWithError:[self createErrorWithCode:DLNetworkingErrorConnectionClosed]];
				}
			}
			break;
		}
	}

	// if the server is not previously set and awaiting no more players
	if (!_peerServer && match.expectedPlayerCount == 0)
	{
		[self assignServer];
	}
}

-(void)match:(GKMatch *)match didFailWithError:(NSError *)error
{
	NSLog(@"DLNetworking encountered a 'didFailWithError'.");
}

@end