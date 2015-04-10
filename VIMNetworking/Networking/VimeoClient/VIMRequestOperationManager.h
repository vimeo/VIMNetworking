//
//  VIMVimeoClient.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/24/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@class VIMRequestDescriptor;
@class VIMServerResponse;
@class VIMSession;

@protocol VIMRequestToken;

typedef void (^VIMFetchCompletionBlock)(VIMServerResponse *response, NSError *error);

extern NSString * const kVimeoClientErrorDomain;

@interface VIMRequestOperationManager : AFHTTPRequestOperationManager

+ (VIMRequestOperationManager *)sharedManager;

- (id<VIMRequestToken>)fetchWithRequestDescriptor:(VIMRequestDescriptor *)descriptor
                                          handler:(id)handler
                                  completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (void)cancelRequest:(id<VIMRequestToken>)request;

- (void)cancelAllRequestsForHandler:(id)handler;

@end
