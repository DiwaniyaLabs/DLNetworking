//
//  DLNetworkingPeerDummy.m
//  iSibeeta
//
//  Created by Mansour Alsarraf on 7/31/12.
//
//

#import "DLNetworkingPeerDummy.h"

#import "DLNetworkingDummyClient.h"

@implementation DLNetworkingPeerDummy

+(id)peerWithDummyInstance:(DLNetworkingDummyClient *)clientInstance andServerInstance:(DLNetworking *)serverInstance
{
	return [[self alloc] initWithDummyInstance:clientInstance andServerInstance:serverInstance];
}

-(id)initWithDummyInstance:(DLNetworkingDummyClient *)clientInstance andServerInstance:(DLNetworking *)serverInstance
{
	if ( (self = [self init]) )
	{
		peerConnection = clientInstance;
		peerConnectionServer = serverInstance;
		peerID = clientInstance.instanceID;
		_isDummy = YES;
	}
	
	return self;
}

-(DLNetworkingDummyClient *)dummyInstance
{
	return peerConnection;
}

-(DLNetworking *)serverInstance
{
	return peerConnectionServer;
}

@end
