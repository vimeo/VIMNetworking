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
- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task;

@optional
- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishWithLocation:(NSURL *)location;

// Tasks implementing this method to return NO must be prepared
// To call -callBackgroundEventsCompletionHandler at the appropriate time [AH]

- (BOOL)sessionManagerShouldCallBackgroundEventsCompletionHandler:(VIMNetworkTaskSessionManager *)sessionManager;

@end

@interface VIMNetworkTaskSessionManager : AFHTTPSessionManager

@property (nonatomic, weak) id<VIMNetworkTaskSessionManagerDelegate> delegate;

@property (nonatomic, copy) ApplicationDelegateCompletionHandler completionHandler;

- (void)setupBlocks;

// Call this method only if you return NO from sessionManagerShouldCallBackgroundEventsCompletionHandler: [AH]
- (void)callBackgroundEventsCompletionHandler;

@end
