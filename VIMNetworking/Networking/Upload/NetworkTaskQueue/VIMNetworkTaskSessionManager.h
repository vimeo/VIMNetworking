//
//  VIMNetworkTaskSessionManager.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/8/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@class VIMNetworkTaskSessionManager;

typedef void (^ApplicationDelegateCompletionHandler)(void);

@protocol VIMNetworkTaskSessionManagerDelegate <NSObject>

@required
- (void)sessionManager:(nonnull VIMNetworkTaskSessionManager *)sessionManager taskDidComplete:(nonnull NSURLSessionTask *)task;

@optional
- (void)sessionManager:(nonnull VIMNetworkTaskSessionManager *)sessionManager downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishWithLocation:(nullable NSURL *)location;

// Tasks implementing this method to return NO must be prepared
// To call -callBackgroundEventsCompletionHandler at the appropriate time [AH]

- (BOOL)sessionManagerShouldCallBackgroundEventsCompletionHandler:(nonnull VIMNetworkTaskSessionManager *)sessionManager;

@end

@interface VIMNetworkTaskSessionManager : AFHTTPSessionManager

@property (nonatomic, weak, nullable) id<VIMNetworkTaskSessionManagerDelegate> delegate;

@property (nonatomic, copy, nullable) ApplicationDelegateCompletionHandler completionHandler;

- (void)setupBlocks;

// Call this method only if you return NO from sessionManagerShouldCallBackgroundEventsCompletionHandler: [AH]
- (void)callBackgroundEventsCompletionHandler;

@end
