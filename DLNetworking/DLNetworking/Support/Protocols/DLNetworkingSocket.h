//
//  DLNetworkingSocket.h
//  Diwaniya Network
//
//  Created by Sour on 6/16/12.
//  Copyright (c) 2012 Diwaniya Labs. All rights reserved.
//

#import "DLNetworking.h"

// import socket logic
#import "GCDAsyncSocket.h"

@interface DLNetworkingSocket : DLNetworking <GCDAsyncSocketDelegate>
{
	uint16_t _port;
}

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate withPort:(uint16_t)port;

#pragma mark -
#pragma mark Packet Transmission (Raw)

-(void)SockSendPacket:(NSData *)packet toPeer:(DLNetworkingPeer *)peer;

@end
