//
//  UploadSessionManager.h
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/29/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@class VIMUploadSessionManager;

typedef void (^ApplicationDelegateCompletionHandler)(void);

@protocol VIMUploadSessionManagerDelegate <NSObject>

@required
- (void)sessionManager:(VIMUploadSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task;

@optional
- (void)sessionManager:(VIMUploadSessionManager *)sessionManager downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishWithLocation:(NSURL *)location;

// Tasks implementing this method to return NO must be prepared
// To call -callBackgroundEventsCompletionHandler at the appropriate time [AH]

- (BOOL)sessionManagerShouldCallBackgroundEventsCompletionHandler:(VIMUploadSessionManager *)sessionManager;

@end

@interface VIMUploadSessionManager : AFHTTPSessionManager

@property (nonatomic, weak) id<VIMUploadSessionManagerDelegate> delegate;

@property (nonatomic, copy) ApplicationDelegateCompletionHandler completionHandler;

+ (instancetype)sharedAppInstance;
+ (instancetype)sharedExtensionInstance;

- (void)setupBlocks;

// Call this method only if you return NO from sessionManagerShouldCallBackgroundEventsCompletionHandler: [AH]
- (void)callBackgroundEventsCompletionHandler;

@end
