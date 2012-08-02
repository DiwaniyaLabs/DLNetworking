//
//  DLNetworkingDummyClient.h
//  DLNetworking
//
//  Created by Mansour Alsarraf on 7/30/12.
//
//

#import "DLNetworking.h"

@interface DLNetworkingDummyClient : DLNetworking
{
	NSString *instanceID;
}

@property (nonatomic, readonly) NSString *instanceID;

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id)delegate;

#pragma mark -
#pragma mark Local Instance generic

-(void)instanceDidDisconnect:(DLNetworkingPeer *)peer;

-(void)instanceDidReceivePacket:(NSData *)packet fromPeer:(DLNetworkingPeer *)peer;

#pragma mark -
#pragma mark Local Instance client-specific

-(void)instanceDidConnectToPeer:(DLNetworkingPeer *)peer;

@end
