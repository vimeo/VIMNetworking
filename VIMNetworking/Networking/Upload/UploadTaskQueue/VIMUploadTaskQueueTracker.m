//
//  UploadQueueTracker.m
//  Smokescreen
//
//  Created by Hanssen, Alfie on 4/3/15.
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

#import "VIMUploadTaskQueueTracker.h"
#import "VIMUploadTaskQueue.h"
#import "VIMVideoAsset.h"
#import "VIMCache.h"

NSString *const VIMUploadTaskQueueTracker_CurrentVideoAssetDidChangeNotification = @"VIMUploadTaskQueueTracker_CurrentVideoAssetDidChangeNotification";
NSString *const VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification = @"VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification";
NSString *const VIMUploadTaskQueueTracker_DidAddQueuedAssetsNotification = @"VIMUploadTaskQueueTracker_DidAddQueuedAssetsNotification";
NSString *const VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification = @"VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification";
NSString *const VIMUploadTaskQueueTracker_DidRemoveFailedAssetsNotification = @"VIMUploadTaskQueueTracker_DidRemoveFailedAssetsNotification";
NSString *const VIMUploadTaskQueueTracker_QueuedAssetDidFailNotification = @"VIMUploadTaskQueueTracker_QueuedAssetDidFailNotification";
NSString *const VIMUploadTaskQueueTracker_FailedAssetDidRetryNotification = @"VIMUploadTaskQueueTracker_FailedAssetDidRetryNotification";

NSString *const VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey = @"VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey";
NSString *const VIMUploadTaskQueueTracker_FailedAssetsCacheKey = @"VIMUploadTaskQueueTracker_FailedAssetsCacheKey";
NSString *const VIMUploadTaskQueueTracker_AssetIndicesKey = @"VIMUploadTaskQueueTracker_AssetIndicesKey";
NSString *const VIMUploadTaskQueueTracker_OriginalIndexKey = @"VIMUploadTaskQueueTracker_OriginalIndexKey";
NSString *const VIMUploadTaskQueueTracker_NewIndexKey = @"VIMUploadTaskQueueTracker_NewIndexKey";
NSString *const VIMUploadTaskQueueTracker_QueuedAssetsKey = @"VIMUploadTaskQueueTracker_QueuedAssetsKey";
NSString *const VIMUploadTaskQueueTracker_FailedAssetsKey = @"VIMUploadTaskQueueTracker_FailedAssetsKey";
NSString *const VIMUploadTaskQueueTracker_AssetsKey = @"VIMUploadTaskQueueTracker_AssetsKey";

static void *UploadStateContext = &UploadStateContext;

@interface VIMUploadTaskQueueTracker ()

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong, readwrite) VIMVideoAsset *currentVideoAsset;
@property (nonatomic, strong, readwrite) NSMutableArray *videoAssets;
@property (nonatomic, strong, readwrite) NSMutableArray *failedAssets;

@property (nonatomic, strong) NSMutableSet *successfulAssetIdentifiers;

@end

@implementation VIMUploadTaskQueueTracker

- (void)dealloc
{
    [self save];
    
    [self removeObservers];
}

- (instancetype)init
{
    NSAssert(NO, @"Use -initWithName:");
    return nil;
}

- (instancetype)initWithName:(NSString *)name
{
    NSParameterAssert(name);
    
    self = [super init];
    if (self)
    {
        _name = name;
        
        _videoAssets = [NSMutableArray array];
        _failedAssets = [NSMutableArray array];
        _successfulAssetIdentifiers = [NSMutableSet set];
        
        [self load];
        
        [self addObservers];
    }
    
    return self;
}

#pragma mark - Public API

- (void)ignoreFailedAsset:(VIMVideoAsset *)videoAsset
{
    NSInteger index = [self.failedAssets indexOfObject:videoAsset];
    NSAssert(index != NSNotFound, @"Invalid index");
    
    if (index == NSNotFound)
    {
        return;
    }
    
    [self.failedAssets removeObjectAtIndex:index];
    
    NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)]};
    [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveFailedAssetsNotification
                                                        object:self.failedAssets
                                                      userInfo:userInfo];
}

- (VIMVideoAsset *)assetForIdentifier:(NSString *)identifier
{
    if (!identifier)
    {
        return nil;
    }
    
    if ([self.currentVideoAsset.identifier isEqualToString:identifier])
    {
        return self.currentVideoAsset;
    }
    
    for (VIMVideoAsset *asset in self.videoAssets)
    {
        if ([asset.identifier isEqualToString:identifier])
        {
            return asset;
        }
    }
    
    for (VIMVideoAsset *asset in self.failedAssets)
    {
        if ([asset.identifier isEqualToString:identifier])
        {
            return asset;
        }
    }
    
    return nil;
}

#pragma mark - Accessors

- (void)setCurrentVideoAsset:(VIMVideoAsset *)currentVideoAsset
{
    if (_currentVideoAsset != currentVideoAsset)
    {
        _currentVideoAsset = currentVideoAsset;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_CurrentVideoAssetDidChangeNotification
                                                            object:currentVideoAsset];
    }
}

#pragma mark - Notifications

- (void)addObservers
{
    // TODO: On what thread do these notifications come in on? [AH]
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAssociateAssetsWithTasks:)
                                                 name:VIMUploadTaskQueue_DidAssociateAssetsWithTasksNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddAssets:)
                                                 name:VIMUploadTaskQueue_DidAddAssetsNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCancelAsset:)
                                                 name:VIMUploadTaskQueue_DidCancelAssetNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCancelAllAssets:)
                                                 name:VIMUploadTaskQueue_DidCancelAllAssetsNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didAssociateAssetsWithTasks:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.name])
    {
        return;
    }
    
    NSArray *object = (NSArray *)[notification object];
    if (object && [object isKindOfClass:[NSArray class]])
    {
        [self.videoAssets removeAllObjects];
        [self.videoAssets addObjectsFromArray:object];
        
        for (VIMVideoAsset *videoAsset in object)
        {
            [self addObserversForVideoAsset:videoAsset];
        }
    
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification
                                                            object:nil];
        
        [self save];
    }
}

- (void)didAddAssets:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.name])
    {
        return;
    }

    NSArray *object = (NSArray *)[notification object];
    if (object && [object isKindOfClass:[NSArray class]])
    {
        NSInteger failedIndex = NSNotFound;
        NSInteger index = [self.videoAssets count];
        NSMutableArray *indices = [NSMutableArray array];
        
        [self.videoAssets addObjectsFromArray:object];
    
        for (VIMVideoAsset *videoAsset in object)
        {
            [indices addObject:@(index)];
            index++;
            
            // If this is a failed asset being retried, remove it from the failed list [AH]
            failedIndex = [self.failedAssets indexOfObject:videoAsset];
            if (failedIndex != NSNotFound)
            {
                [self.failedAssets removeObjectAtIndex:failedIndex];
            }
            
            [self addObserversForVideoAsset:videoAsset];
        }

        if ([object count] == 1)
        {
            if (failedIndex != NSNotFound)
            {
                NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_OriginalIndexKey : @(failedIndex),
                                           VIMUploadTaskQueueTracker_NewIndexKey : @([self.videoAssets count] - 1),
                                           VIMUploadTaskQueueTracker_QueuedAssetsKey : self.videoAssets,
                                           VIMUploadTaskQueueTracker_FailedAssetsKey : self.failedAssets,
                                           VIMUploadTaskQueueTracker_AssetsKey : object};
                [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_FailedAssetDidRetryNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            
                return;
            }
        }

        NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : indices,
                                   VIMUploadTaskQueueTracker_AssetsKey : object};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidAddQueuedAssetsNotification
                                                            object:self.videoAssets
                                                          userInfo:userInfo];        

        [self save];
    }
}

- (void)didCancelAsset:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.name])
    {
        return;
    }

    VIMVideoAsset *object = (VIMVideoAsset *)[notification object];
    if (object && [object isKindOfClass:[VIMVideoAsset class]])
    {
        if ([object.identifier isEqualToString:self.currentVideoAsset.identifier])
        {
            self.currentVideoAsset = nil;
        }
        
        NSInteger index = [self.videoAssets indexOfObject:object];
        NSAssert(index != NSNotFound, @"Invalid index");
    
        [self removeObserversForVideoAsset:object];

        [self.videoAssets removeObjectAtIndex:index];
        
        NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)],
                                   VIMUploadTaskQueueTracker_AssetsKey : @[object]};
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification
                                                            object:self.videoAssets
                                                          userInfo:userInfo];
        
        [self save];
    }
}

- (void)didCancelAllAssets:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.name])
    {
        return;
    }

    for (VIMVideoAsset *videoAsset in self.videoAssets)
    {
        [self removeObserversForVideoAsset:videoAsset];
    }
    
    [self.videoAssets removeAllObjects];
    self.currentVideoAsset = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification
                                                        object:self.videoAssets];
    
    [self save];
}

#pragma mark - KVO

- (void)addObserversForVideoAsset:(VIMVideoAsset *)videoAsset
{
    [videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
}

- (void)removeObserversForVideoAsset:(VIMVideoAsset *)videoAsset
{
    @try
    {
        [videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) context:UploadStateContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadStateContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadState))])
        {
            VIMUploadState newState = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadState:newState didChangeForVideoAsset:(VIMVideoAsset *)object];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)uploadState:(VIMUploadState)state didChangeForVideoAsset:(VIMVideoAsset *)videoAsset
{
    NSParameterAssert(videoAsset);
    
    switch (state)
    {
        case VIMUploadState_None: // TODO: Is this ever called? Should we specifically not implement this case? [AH]
        {
            [self.videoAssets removeObject:videoAsset];
            [self removeObserversForVideoAsset:videoAsset];
            break;
        }
        case VIMUploadState_Enqueued:
            break;
            
        case VIMUploadState_CreatingRecord:
        case VIMUploadState_UploadingFile:
        case VIMUploadState_ActivatingRecord:
        case VIMUploadState_AddingMetadata:
        {
            self.currentVideoAsset = videoAsset;
            break;
        }
        case VIMUploadState_Succeeded:
        {
            NSInteger index = [self.videoAssets indexOfObject:videoAsset];
            NSAssert(index != NSNotFound, @"Invalid index");
            
            [self.videoAssets removeObjectAtIndex:index];
            [self removeObserversForVideoAsset:videoAsset];
            [self.successfulAssetIdentifiers addObject:videoAsset.identifier];
            self.currentVideoAsset = nil;
            
            NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)],
                                       VIMUploadTaskQueueTracker_AssetsKey : @[videoAsset]};
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification
                                                                object:self.videoAssets
                                                              userInfo:userInfo];

            break;
        }
        case VIMUploadState_Failed:
        {
            if (videoAsset.error.code != NSURLErrorCancelled) // Cancellation is handled above via notification [AH]
            {
                NSInteger index = [self.videoAssets indexOfObject:videoAsset];
                NSAssert(index != NSNotFound, @"Invalid index");
    
                [self.videoAssets removeObjectAtIndex:index];
                [self removeObserversForVideoAsset:videoAsset];
                [self.failedAssets addObject:videoAsset];
                self.currentVideoAsset = nil;

                NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_OriginalIndexKey : @(index),
                                           VIMUploadTaskQueueTracker_NewIndexKey : @([self.failedAssets count] - 1),
                                           VIMUploadTaskQueueTracker_QueuedAssetsKey : self.videoAssets,
                                           VIMUploadTaskQueueTracker_FailedAssetsKey : self.failedAssets,
                                           VIMUploadTaskQueueTracker_AssetsKey : @[videoAsset]};
                [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_QueuedAssetDidFailNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            }
            break;
        }
        default:
            break;
   }
    
    [self save];
}

#pragma mark - Caching

- (void)load
{
    id successObject = [[VIMCache sharedCache] objectForKey:VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey];
    if (successObject && [successObject isKindOfClass:[NSSet class]])
    {
        self.successfulAssetIdentifiers = [NSMutableSet setWithSet:successObject];
    }

    id failureObject = [[VIMCache sharedCache] objectForKey:VIMUploadTaskQueueTracker_FailedAssetsCacheKey];
    if (failureObject && [failureObject isKindOfClass:[NSArray class]])
    {
        self.failedAssets = [NSMutableArray arrayWithArray:failureObject];
    }
}

- (void)save
{
    [[VIMCache sharedCache] setObject:self.successfulAssetIdentifiers forKey:VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey];
    [[VIMCache sharedCache] setObject:self.failedAssets forKey:VIMUploadTaskQueueTracker_FailedAssetsCacheKey];
}

@end
