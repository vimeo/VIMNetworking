//
//  ConnectionAwareUploadQueue.h
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 12/22/14.
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

#import <Foundation/Foundation.h>
#import "VIMNetworkTaskQueue.h"

@class VIMVideoAsset;
@class VIMVideoMetadata;
@class VIMUploadTaskQueueTracker;

extern NSString *const VIMUploadTaskQueue_DidAssociateAssetsWithTasksNotification;
extern NSString *const VIMUploadTaskQueue_DidAddAssetsNotification;
extern NSString *const VIMUploadTaskQueue_DidCancelAssetNotification;
extern NSString *const VIMUploadTaskQueue_DidCancelAllAssetsNotification;

extern NSString *const VIMUploadTaskQueue_NameKey;

typedef void(^AddMetadataCompletionBlock)(BOOL didAdd);

@interface VIMUploadTaskQueue : VIMNetworkTaskQueue

@property (nonatomic, strong, readonly) VIMUploadTaskQueueTracker *uploadQueueTracker;

+ (instancetype)sharedAppQueue;
+ (instancetype)sharedExtensionQueue;

- (void)uploadVideoAssets:(NSArray *)videoAssets;

- (void)cancelUploadForVideoAsset:(VIMVideoAsset *)videoAsset;
- (void)cancelAllUploads;

- (NSMutableArray *)associateVideoAssetsWithUploads:(NSArray *)videoAssets;

- (void)addMetadata:(VIMVideoMetadata *)metadata toVideoAsset:(VIMVideoAsset *)videoAsset withCompletionBlock:(AddMetadataCompletionBlock)completionBlock;

@end
