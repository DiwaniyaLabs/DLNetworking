//
//  DLNetworkingGameKit.h
//  Diwaniya Client
//
//  Created by Sour on 6/18/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#import "DLNetworking.h"

// import GameKit on iOS devices
#import "GameKit/GameKit.h"

@interface DLNetworkingGameKit : DLNetworking <GKSessionDelegate>
{
	// the unique session ID (used to discover players)
	NSString *_sessionID;
	
	// the server's peerID (used to send packets to server)
	NSString *_peerServerID;
}

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate withSessionID:(NSString *)sessionID;

-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context;

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(NSArray *)peerIDsFromPeers:(NSArray *)peers except:(DLNetworkingPeer *)peerException;

-(void)GKSendPacket:(NSData *)packet toPeers:(NSArray *)peers except:(DLNetworkingPeer *)peer;

-(void)GKSendPacketToAll:(NSData *)packet;

@end
