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

@synthesize dummyInstance = _peerConnectionClient;
@synthesize serverInstance = _peerConnectionServer;

+(id)peerWithDelegate:(id<DLNetworkingDelegate>)delegate dummyInstance:(DLNetworkingDummyClient *)dummyInstance serverInstance:(DLNetworking *)serverInstance
{
	return [[self alloc] initWithDelegate:delegate dummyInstance:dummyInstance serverInstance:serverInstance];
}

-(id)initWithDelegate:(id<DLNetworkingDelegate>)delegate dummyInstance:(DLNetworkingDummyClient *)dummyInstance serverInstance:(DLNetworking *)serverInstance
{
	if ( (self = [super init]) )
	{
		_delegate = delegate;
		_peerConnectionClient = dummyInstance;
		_peerConnectionServer = serverInstance;
		_peerID = dummyInstance.instanceID;
		
		_isDummy = YES;
	}
	
	return self;
}

// overridden so other protocols can read this
-(id)peerConnection
{
	return _peerConnectionClient;
}

@end
