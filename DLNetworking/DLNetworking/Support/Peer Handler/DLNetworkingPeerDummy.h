//
//  DLNetworkingPeerDummy.h
//  iSibeeta
//
//  Created by Mansour Alsarraf on 7/31/12.
//
//

#import "DLNetworkingPeer.h"

@class DLNetworking;
@class DLNetworkingDummyClient;

@interface DLNetworkingPeerDummy : DLNetworkingPeer
{
	iweak id peerConnectionClient;
	iweak id peerConnectionServer;
}

+(id)peerWithDummyInstance:(DLNetworkingDummyClient *)clientInstance andServerInstance:(DLNetworking *)serverInstance;

-(id)initWithDummyInstance:(DLNetworkingDummyClient *)clientInstance andServerInstance:(DLNetworking *)serverInstance;

-(DLNetworkingDummyClient *)dummyInstance;

-(DLNetworking *)serverInstance;

@end
