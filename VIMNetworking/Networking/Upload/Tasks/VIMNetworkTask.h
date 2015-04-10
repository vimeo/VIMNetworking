//
//  NetworkTask.h
//  Hermes
//
//  Created by Hanssen, Alfie on 3/3/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMTask.h"
#import "VIMUploadSessionManager.h"
#import "AFHTTPSessionManager+Extensions.h"
#import "VIMUploadDebugger.h"

#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

@interface VIMNetworkTask : VIMTask <VIMUploadSessionManagerDelegate>

@property (nonatomic, strong) VIMUploadSessionManager *sessionManager;
@property (nonatomic, assign) NSUInteger backgroundTaskIdentifier;

@property (nonatomic, strong, readonly) PHAsset *phAsset;
@property (nonatomic, strong, readonly) AVURLAsset *URLAsset;

- (instancetype)initWithPHAsset:(PHAsset *)phAsset;
- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset;

- (void)taskDidComplete;
- (void)taskDidStart;

@end
