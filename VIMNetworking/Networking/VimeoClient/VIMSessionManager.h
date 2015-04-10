//
//  VIMVimeoSessionManager.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface VIMSessionManager : AFHTTPSessionManager

@property (nonatomic, copy) void(^backgroundSessionCompletionHandler)();

+ (VIMSessionManager *)sharedAppManager;
+ (VIMSessionManager *)sharedExtensionManager;

- (instancetype)initWithDefaultSession;
- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID;
//- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID sharedContainerID:(NSString *)sharedContainerID;
//- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

@end
