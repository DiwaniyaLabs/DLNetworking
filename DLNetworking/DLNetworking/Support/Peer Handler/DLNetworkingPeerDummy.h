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
	iweak id _peerConnectionClient;
	iweak id _peerConnectionServer;
}

@property (nonatomic, pweak) id dummyInstance;
@property (nonatomic, pweak) id serverInstance;

+(id)peerWithDelegate:(id<DLNetworkingDelegate>)delegate dummyInstance:(DLNetworkingDummyClient *)dummyInstance serverInstance:(DLNetworking *)serverInstance;

-(id)initWithDelegate:(id<DLNetworkingDelegate>)delegate dummyInstance:(DLNetworkingDummyClient *)dummyInstance serverInstance:(DLNetworking *)serverInstance;

-(DLNetworkingDummyClient *)dummyInstance;

-(DLNetworking *)serverInstance;

@end
