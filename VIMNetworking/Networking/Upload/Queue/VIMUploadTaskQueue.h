//
//  ConnectionAwareUploadQueue.h
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 12/22/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VIMTaskQueue.h"

@class VIMVideoAsset;
@class VIMVideoMetadata;

extern NSString *const VIMUploadTaskQueue_DidSuspendOrResumeNotification;

typedef void(^AddMetadataCompletionBlock)(BOOL didAdd);

@interface VIMUploadTaskQueue : VIMTaskQueue

@property (nonatomic, assign, getter=isCellularUploadEnabled) BOOL cellularUploadEnabled;

+ (instancetype)sharedAppQueue;
+ (instancetype)sharedExtensionQueue;

- (void)uploadVideoAssets:(NSArray *)videoAssets;
- (void)uploadVideoAsset:(VIMVideoAsset *)videoAsset;

- (void)cancelUploadForVideoAsset:(VIMVideoAsset *)videoAsset;
- (void)cancelAllUploads;

- (void)associateVideoAssetsWithUploads:(NSArray *)videoAssets;

- (void)addMetadata:(VIMVideoMetadata *)metadata toVideoAsset:(VIMVideoAsset *)videoAsset withCompletionBlock:(AddMetadataCompletionBlock)completionBlock;

@end
