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

//#import "VIMSession.h"

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
NSString *const VIMUploadTaskQueueTracker_SessionIdentifierKey = @"VIMUploadTaskQueueTracker_SessionIdentifierKey";

static void *UploadStateContext = &UploadStateContext;

@interface VIMUploadTaskQueueTracker ()

@property (nonatomic, strong) NSString *sessionIdentifier;

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

- (instancetype)initWithSessionIdentifier:(NSString *)sessionIdentifier
{
    NSParameterAssert(sessionIdentifier);
    
    self = [super init];
    if (self)
    {
        _sessionIdentifier = sessionIdentifier;
        
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
    [self indexOfFailedAsset:videoAsset completion:^(NSInteger index, VIMVideoAsset *asset) {

        NSAssert(index != NSNotFound, @"Invalid index");
        
        if (index == NSNotFound)
        {
            return;
        }
        
        asset.uploadState = VIMUploadState_None;
        
        [self.failedAssets removeObjectAtIndex:index];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)]};
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveFailedAssetsNotification
                                                                object:self.failedAssets
                                                              userInfo:userInfo];
            
        });

    }];
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

#pragma mark - Private API

- (void)indexOfFailedAsset:(VIMVideoAsset *)videoAsset completion:(void (^)(NSInteger index, VIMVideoAsset *asset))completion
{
    NSInteger index = NSNotFound;
    VIMVideoAsset *asset = nil;
    
    for (NSInteger i = 0; i < [self.failedAssets count]; i++)
    {
        VIMVideoAsset *failedAsset = self.failedAssets[i];
        if ([failedAsset.identifier isEqualToString:videoAsset.identifier])
        {
            index = i;
            asset = failedAsset;
            
            break;
        }
    }
    
    if (completion)
    {
        completion(index, asset);
    }
}

#pragma mark - Accessors

- (void)setCurrentVideoAsset:(VIMVideoAsset *)currentVideoAsset
{
    if (_currentVideoAsset != currentVideoAsset)
    {
        [self removeObserversForVideoAsset:_currentVideoAsset];

        _currentVideoAsset = currentVideoAsset;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_CurrentVideoAssetDidChangeNotification
                                                                object:currentVideoAsset];
        
        });
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(authenticatedUserDidChange:)
//                                                 name:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didAssociateAssetsWithTasks:(NSNotification *)notification
{
//    if ([VIMSession sharedSession].account.user == nil)
//    {
//        return;
//    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.sessionIdentifier])
    {
        return;
    }
    
    NSArray *object = (NSArray *)[notification object];
    if (object && [object isKindOfClass:[NSArray class]])
    {
        for (VIMVideoAsset *videoAsset in self.videoAssets)
        {
            [self removeObserversForVideoAsset:videoAsset];
        }

        [self.videoAssets removeAllObjects];
        [self.videoAssets addObjectsFromArray:object];
        
        for (VIMVideoAsset *videoAsset in object)
        {
            [self addObserversForVideoAsset:videoAsset];
            [self uploadState:videoAsset.uploadState didChangeForVideoAsset:videoAsset];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification
                                                                object:nil];
        
        });
        
        [self save];
    }
}

- (void)didAddAssets:(NSNotification *)notification
{
//    if ([VIMSession sharedSession].account.user == nil)
//    {
//        return;
//    }

    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.sessionIdentifier])
    {
        return;
    }

    NSArray *object = (NSArray *)[notification object];
    if (object && [object isKindOfClass:[NSArray class]])
    {
        __block NSInteger failedIndex = NSNotFound;
        NSInteger index = [self.videoAssets count];
        NSMutableArray *indices = [NSMutableArray array];
        
        [self.videoAssets addObjectsFromArray:object];
    
        for (VIMVideoAsset *videoAsset in object)
        {
            [indices addObject:@(index)];
            index++;
            
            // If this is a failed asset being retried, remove it from the failed list [AH]
            [self indexOfFailedAsset:videoAsset completion:^(NSInteger index, VIMVideoAsset *asset) {

                failedIndex = index;
                
                if (failedIndex != NSNotFound)
                {
                    [self removeObserversForVideoAsset:asset];
                    
                    [self.failedAssets removeObjectAtIndex:failedIndex];
                }

            }];
            
            [self addObserversForVideoAsset:videoAsset];
        }

        if ([object count] == 1)
        {
            if (failedIndex != NSNotFound)
            {
                dispatch_async(dispatch_get_main_queue(), ^{

                    NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_OriginalIndexKey : @(failedIndex),
                                               VIMUploadTaskQueueTracker_NewIndexKey : @([self.videoAssets count] - 1),
                                               VIMUploadTaskQueueTracker_QueuedAssetsKey : self.videoAssets,
                                               VIMUploadTaskQueueTracker_FailedAssetsKey : self.failedAssets,
                                               VIMUploadTaskQueueTracker_AssetsKey : object,
                                               VIMUploadTaskQueueTracker_SessionIdentifierKey : self.sessionIdentifier};
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_FailedAssetDidRetryNotification
                                                                        object:nil
                                                                      userInfo:userInfo];

                });
                
                return;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{

            NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : indices,
                                       VIMUploadTaskQueueTracker_AssetsKey : object,
                                       VIMUploadTaskQueueTracker_SessionIdentifierKey : self.sessionIdentifier};
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidAddQueuedAssetsNotification
                                                                object:self.videoAssets
                                                              userInfo:userInfo];        

        });
        
        [self save];
    }
}

- (void)didCancelAsset:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.sessionIdentifier])
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

        [self removeObserversForVideoAsset:object];

        NSInteger index = [self.videoAssets indexOfObject:object];
//        NSAssert(index != NSNotFound, @"Invalid index");

        if (index == NSNotFound)
        {
            [self save];

            return;
        }

        [self.videoAssets removeObjectAtIndex:index];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)],
                                       VIMUploadTaskQueueTracker_AssetsKey : @[object],
                                       VIMUploadTaskQueueTracker_SessionIdentifierKey : self.sessionIdentifier};
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification
                                                                object:self.videoAssets
                                                              userInfo:userInfo];

        });
        
        [self save];
    }
}

- (void)didCancelAllAssets:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *name = userInfo[VIMUploadTaskQueue_NameKey];
    if (![name isEqualToString:self.sessionIdentifier])
    {
        return;
    }

    for (VIMVideoAsset *videoAsset in self.videoAssets)
    {
        [self removeObserversForVideoAsset:videoAsset];
    }
    
    [self.videoAssets removeAllObjects];
    self.currentVideoAsset = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification
                                                            object:self.videoAssets];

    });
    
    [self save];
}

// TODO: what do we need to replace this logic with? [AH] 9/1/2015

//- (void)authenticatedUserDidChange:(NSNotification *)notification
//{
//    if ([VIMSession sharedSession].account.user == nil) // User logged out
//    {
//        for (VIMVideoAsset *videoAsset in self.videoAssets)
//        {
//            [self removeObserversForVideoAsset:videoAsset];
//        }
//        
//        [self.videoAssets removeAllObjects];
//        self.currentVideoAsset = nil;
//
//        [self.successfulAssetIdentifiers removeAllObjects];
//        [self.failedAssets removeAllObjects];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification
//                                                                object:self.videoAssets];
//
//        });
//        
//        [self save];
//    }
//}

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
            self.currentVideoAsset = nil;
            [self.successfulAssetIdentifiers addObject:videoAsset.identifier];

            NSInteger index = [self.videoAssets indexOfObject:videoAsset];
//            NSAssert(index != NSNotFound, @"Invalid index");
            
            if (index == NSNotFound)
            {
                break;
            }

            [self.videoAssets removeObjectAtIndex:index];
            
            dispatch_async(dispatch_get_main_queue(), ^{

                NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_AssetIndicesKey : @[@(index)],
                                           VIMUploadTaskQueueTracker_AssetsKey : @[videoAsset],
                                           VIMUploadTaskQueueTracker_SessionIdentifierKey : self.sessionIdentifier};
                [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification
                                                                    object:self.videoAssets
                                                                  userInfo:userInfo];

            });
            
            break;
        }
        case VIMUploadState_Failed:
        {
            if (videoAsset.error.code != NSURLErrorCancelled) // Cancellation is handled above via notification [AH]
            {
                [self.failedAssets addObject:videoAsset];
                self.currentVideoAsset = nil;

                NSInteger index = [self.videoAssets indexOfObject:videoAsset];
//                NSAssert(index != NSNotFound, @"Invalid index");
    
                if (index == NSNotFound)
                {
                    break;
                }

                [self.videoAssets removeObjectAtIndex:index];

                dispatch_async(dispatch_get_main_queue(), ^{

                    NSDictionary *userInfo = @{VIMUploadTaskQueueTracker_OriginalIndexKey : @(index),
                                               VIMUploadTaskQueueTracker_NewIndexKey : @([self.failedAssets count] - 1),
                                               VIMUploadTaskQueueTracker_QueuedAssetsKey : self.videoAssets,
                                               VIMUploadTaskQueueTracker_FailedAssetsKey : self.failedAssets,
                                               VIMUploadTaskQueueTracker_AssetsKey : @[videoAsset],
                                               VIMUploadTaskQueueTracker_SessionIdentifierKey : self.sessionIdentifier};
                    [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueueTracker_QueuedAssetDidFailNotification
                                                                        object:nil
                                                                      userInfo:userInfo];
                    
                });
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
    id successObject = [VIMUploadTaskQueueTracker unarchiveObjectForKey:VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey];
    if (successObject && [successObject isKindOfClass:[NSArray class]])
    {
        self.successfulAssetIdentifiers = [NSMutableSet setWithArray:successObject];
    }

    id failureObject = [VIMUploadTaskQueueTracker unarchiveObjectForKey:VIMUploadTaskQueueTracker_FailedAssetsCacheKey];
    if (failureObject && [failureObject isKindOfClass:[NSArray class]])
    {
        self.failedAssets = [NSMutableArray arrayWithArray:failureObject];
    }
}

- (void)save
{
    NSArray *array = [self.successfulAssetIdentifiers allObjects];
    [VIMUploadTaskQueueTracker archiveObject:array forKey:VIMUploadTaskQueueTracker_SuccessfulAssetIdentifiersCacheKey];

    [VIMUploadTaskQueueTracker archiveObject:[self.failedAssets copy] forKey:VIMUploadTaskQueueTracker_FailedAssetsCacheKey];
}

+ (id)unarchiveObjectForKey:(NSString *)key
{
    NSAssert(key != nil, @"key cannot be nil");
    if (key == nil)
    {
        return nil;
    }
    
    __block id object = nil;
    
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (data)
    {
        NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        @try
        {
            object = [keyedUnarchiver decodeObject];
        }
        @catch (NSException *exception)
        {
            NSLog(@"UserDefaultsController: An exception occured while unarchiving: %@", exception);
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [keyedUnarchiver finishDecoding];
    }
    
    return object;
}

+ (void)archiveObject:(id)object forKey:(NSString *)key
{
    NSAssert(key != nil, @"key cannot be nil");
    if (key == nil)
    {
        return;
    }
    
    dispatch_async([VIMUploadTaskQueueTracker archiveQueue], ^{
        
        if (object)
        {
            NSMutableData *data = [NSMutableData new];
            NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            
            [keyedArchiver encodeObject:object];
            [keyedArchiver finishEncoding];
            
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    });
}

+ (dispatch_queue_t)archiveQueue
{
    static dispatch_queue_t archiveQueue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        archiveQueue = dispatch_queue_create("com.vimeo.uploadTaskQueueTracker.archiveQueue", DISPATCH_QUEUE_SERIAL);
    
    });
    
    return archiveQueue;
}

@end
