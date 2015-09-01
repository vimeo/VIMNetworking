//
//  ConnectionAwareUploadQueue.m
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

#import "VIMUploadTaskQueue.h"
#import "VIMVideoAsset.h"
#import "VIMUploadTask.h"
#import "VIMUploadTaskQueueTracker.h"
#import "VIMNetworkTaskSessionManager.h"

NSString *const VIMUploadTaskQueue_DidAssociateAssetsWithTasksNotification = @"VIMUploadTaskQueue_DidAssociateAssetsWithTasksNotification";
NSString *const VIMUploadTaskQueue_DidAddAssetsNotification = @"VIMUploadTaskQueue_DidAddAssetsNotification";
NSString *const VIMUploadTaskQueue_DidCancelAssetNotification = @"VIMUploadTaskQueue_DidCancelAssetNotification";
NSString *const VIMUploadTaskQueue_DidCancelAllAssetsNotification = @"VIMUploadTaskQueue_DidCancelAllAssetsNotification";

NSString *const VIMUploadTaskQueue_NameKey = @"VIMUploadTaskQueue_NameKey";

@interface VIMUploadTaskQueue ()

@property (nonatomic, strong, readwrite) VIMUploadTaskQueueTracker *uploadQueueTracker;

@end

@implementation VIMUploadTaskQueue

- (instancetype)initWithSessionManager:(VIMNetworkTaskSessionManager *)sessionManager
{
    self = [super initWithSessionManager:sessionManager];
    if (self)
    {
        _uploadQueueTracker = [[VIMUploadTaskQueueTracker alloc] initWithSessionIdentifier:sessionManager.session.configuration.identifier];
    }
    
    return self;
}

#pragma mark - Public API

- (void)uploadVideoAssets:(NSArray *)videoAssets
{
    if (![videoAssets count])
    {
        return;
    }

    NSMutableArray *tasks = [NSMutableArray array];
    
    for (VIMVideoAsset *videoAsset in videoAssets)
    {
        VIMUploadTask *task = nil;
        
        if (videoAsset.phAsset)
        {
            task = [[VIMUploadTask alloc] initWithPHAsset:videoAsset.phAsset];
        }
        else if (videoAsset.URLAsset)
        {
            task = [[VIMUploadTask alloc] initWithURLAsset:videoAsset.URLAsset canUploadFromSource:videoAsset.canUploadFromSource];
        }
        
        [self configureTaskBlocks:task forAsset:videoAsset];
        
        videoAsset.uploadState = VIMUploadState_Enqueued;
        
        [tasks addObject:task];
    }
    
    [self addTasks:tasks];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{VIMUploadTaskQueue_NameKey : self.name};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueue_DidAddAssetsNotification object:videoAssets userInfo:userInfo];
    });
}

- (void)cancelUploadForVideoAsset:(VIMVideoAsset *)videoAsset
{
    if (!videoAsset)
    {
        return;
    }

    [self cancelTaskForIdentifier:videoAsset.identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{VIMUploadTaskQueue_NameKey : self.name};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueue_DidCancelAssetNotification object:videoAsset userInfo:userInfo];
    });
}

- (void)cancelAllUploads
{
    [self cancelAllTasks];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{VIMUploadTaskQueue_NameKey : self.name};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueue_DidCancelAllAssetsNotification object:nil userInfo:userInfo];
    });
}

- (NSMutableArray *)associateVideoAssetsWithUploads:(NSArray *)videoAssets
{
    NSMutableArray *associatedAssets = [NSMutableArray array];

    for (VIMVideoAsset *videoAsset in videoAssets)
    {
        VIMUploadTask *task = (VIMUploadTask *)[self taskForIdentifier:videoAsset.identifier];
        if (task)
        {
            [self configureTaskBlocks:task forAsset:videoAsset];
            
            task.uploadStateBlock(task.uploadState);
            
            [associatedAssets addObject:videoAsset];
        }
    }
    
    NSLog(@"%lu new assets. %lu existing descriptors. %lu assets associated", (unsigned long)[videoAssets count], (unsigned long)self.taskCount, (unsigned long)[associatedAssets count]);
    
    dispatch_async(dispatch_get_main_queue(), ^{

        NSDictionary *userInfo = @{VIMUploadTaskQueue_NameKey : self.name};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueue_DidAssociateAssetsWithTasksNotification object:associatedAssets userInfo:userInfo];

    });
    
    return associatedAssets;
}

- (void)addMetadata:(VIMVideoMetadata *)metadata toVideoAsset:(VIMVideoAsset *)videoAsset withCompletionBlock:(AddMetadataCompletionBlock)completionBlock
{
    NSParameterAssert(metadata && videoAsset);
    
    videoAsset.metadata = metadata;
    
    VIMUploadTask *task = (VIMUploadTask *)[self taskForIdentifier:videoAsset.identifier];
    if (task)
    {
        task.videoMetadata = metadata;
    }
    
    if (completionBlock)
    {
        BOOL didAdd = task != nil;
        completionBlock(didAdd);
    }
}

#pragma mark - Private API

- (void)configureTaskBlocks:(VIMUploadTask *)task forAsset:(VIMVideoAsset *)asset
{
    NSParameterAssert(task && asset);
    
    [task setUploadStateBlock:^(VIMUploadState state){
        asset.uploadState = state;
    }];
    
    [task setUploadProgressBlock:^(double progressFraction){
        asset.uploadProgressFraction = progressFraction;
    }];
    
    [task setUploadCompletionBlock:^(NSString *videoURI, NSError *error) {
        asset.videoURI = videoURI;
        asset.error = error;
    }];
}

@end
