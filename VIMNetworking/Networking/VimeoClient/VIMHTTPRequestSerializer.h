//
//  VIMHTTPRequestSerializer.h
//  VIMUpload
//
//  Created by Hanssen, Alfie on 9/1/15.
//
//

#import "AFURLRequestSerialization.h"
#import "VIMRequestSerializerDelegate.h"

@interface VIMHTTPRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, weak) id<VIMRequestSerializerDelegate> delegate;

- (nonnull instancetype)initWithAPIVersionString:(nonnull NSString *)APIVersionString;

@end
