//
//  VIMHTTPRequestSerializer.h
//  Pods
//
//  Created by Hanssen, Alfie on 9/1/15.
//
//

#import "AFURLRequestSerialization.h"
#import "VIMRequestSerializerDelegate.h"

@interface VIMHTTPRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, weak) id<VIMRequestSerializerDelegate> delegate;

@end
