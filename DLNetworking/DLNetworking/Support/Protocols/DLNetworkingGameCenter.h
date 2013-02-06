//
// Created by Sour on 1/29/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DLNetworking.h"

@interface DLNetworkingGameCenter : DLNetworking <GKMatchDelegate>
{
	GKMatch *_match;

	BOOL _isServer;

	DLNetworkingPeer *_peerServer;
}

-(id)initWithDelegate:(id)delegate withGKMatch:(GKMatch *)match;

-(void)GCSendToPeers:(NSArray *)peers packet:(id)packet;


@end