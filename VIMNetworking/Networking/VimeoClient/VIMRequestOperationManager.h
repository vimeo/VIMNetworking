//
//  VIMVimeoClient.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/24/13.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "VIMRequestDescriptor.h"
#import "VIMServerResponse.h"
#import "VIMCache.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@protocol VIMRequestToken;

typedef void (^VIMRequestCompletionBlock)(VIMServerResponse * __nullable response, NSError * __nullable error);

extern NSInteger const kVimeoClientErrorCodeCacheUnavailable;
extern NSString *const __nonnull kVimeoClientErrorDomain;
extern NSString *const __nonnull kVimeoClient_ServiceUnavailableNotification;
extern NSString *const __nonnull kVimeoClient_InvalidTokenNotification;

@interface VIMRequestOperationManager : AFHTTPRequestOperationManager

@property (nonatomic, strong, nullable) VIMCache *cache;

- (nullable id<VIMRequestToken>)requestURI:(nonnull NSString *)URI
                           completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)requestDescriptor:(nonnull VIMRequestDescriptor *)descriptor
                                  completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)requestDescriptor:(nonnull VIMRequestDescriptor *)descriptor
                                          handler:(nonnull id)handler
                                  completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (void)cancelRequest:(nullable id<VIMRequestToken>)request;
- (void)cancelAllRequestsForHandler:(nonnull id)handler;
- (void)cancelAllRequests;

NSDictionary * __nullable VIMParametersFromQueryString(NSString * __nonnull queryString);

@end
