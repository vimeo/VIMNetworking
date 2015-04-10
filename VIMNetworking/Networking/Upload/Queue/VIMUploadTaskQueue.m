//
//  ConnectionAwareUploadQueue.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 12/22/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMUploadTaskQueue.h"
#import "VIMVideoAsset.h"
#import "VIMVideoUploadTask.h"
#import "VIMUploadSessionManager.h"
#import "VIMReachability.h"

NSString *const VIMUploadTaskQueue_DidSuspendOrResumeNotification = @"VIMUploadTaskQueue_DidSuspendOrResumeNotification";

static const NSString *ArchiveKey = @"upload_queue_archive";
static const NSString *SuspendedByUserKey = @"suspended_by_user";
static const NSString *CellularEnabledKey = @"cellular_enabled";

@interface VIMUploadTaskQueue ()

@property (nonatomic, strong) VIMUploadSessionManager *sessionManager;

@property (nonatomic, assign, getter=isSuspendedByUser) BOOL suspendedByUser;

@end

@implementation VIMUploadTaskQueue

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedAppQueue
{
    static VIMUploadTaskQueue *sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithSessionManager:[VIMUploadSessionManager sharedAppInstance]];
    });
    
    return sharedInstance;
}

+ (instancetype)sharedExtensionQueue
{
    static VIMUploadTaskQueue *sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithSessionManager:[VIMUploadSessionManager sharedExtensionInstance]];
    });
    
    return sharedInstance;
}

- (instancetype)initWithSessionManager:(VIMUploadSessionManager *)sessionManager
{
    self = [super initWithName:sessionManager.session.configuration.identifier];
    if (self)
    {
        _sessionManager = sessionManager;
        
        [self loadCommonSettings];
        
        [self resumeIfAllowed];

        [self addObservers];
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
        VIMVideoUploadTask *task = nil;
        
        if (videoAsset.phAsset)
        {
            task = [[VIMVideoUploadTask alloc] initWithPHAsset:videoAsset.phAsset];
        }
        else if (videoAsset.URLAsset)
        {
            task = [[VIMVideoUploadTask alloc] initWithURLAsset:videoAsset.URLAsset];
        }
        
        [self configureTaskBlocks:task forAsset:videoAsset];
        
        videoAsset.uploadState = VIMUploadState_Enqueued;
        
        [tasks addObject:task];
    }
    
    [self addTasks:tasks];
}

- (void)uploadVideoAsset:(VIMVideoAsset *)videoAsset
{
    if (!videoAsset)
    {
        return;
    }

    VIMVideoUploadTask *task = nil;
    
    if (videoAsset.phAsset)
    {
        task = [[VIMVideoUploadTask alloc] initWithPHAsset:videoAsset.phAsset];
    }
    else if (videoAsset.URLAsset)
    {
        task = [[VIMVideoUploadTask alloc] initWithURLAsset:videoAsset.URLAsset];
    }
    
    [self configureTaskBlocks:task forAsset:videoAsset];
    
    videoAsset.uploadState = VIMUploadState_Enqueued;

    [self addTask:task];
}

- (void)cancelUploadForVideoAsset:(VIMVideoAsset *)videoAsset
{
    if (!videoAsset)
    {
        return;
    }

    VIMTask *task = [self taskForIdentifier:videoAsset.identifier];

    [self cancelTask:task];
}

- (void)cancelAllUploads
{
    [self cancelAllTasks];
}

- (void)associateVideoAssetsWithUploads:(NSArray *)videoAssets
{
    if (![videoAssets count])
    {
        return;
    }
    
    NSUInteger associations = 0;
    
    for (VIMVideoAsset *videoAsset in videoAssets)
    {
        VIMVideoUploadTask *task = (VIMVideoUploadTask *)[self taskForIdentifier:videoAsset.identifier];
        if (task)
        {
            [self configureTaskBlocks:task forAsset:videoAsset];
            
            task.uploadStateBlock(task.uploadState);
            
            associations++;
        }
    }
    
    NSLog(@"%lu new assets. %lu existing descriptors. %lu assets associated", (unsigned long)[videoAssets count], (unsigned long)self.taskCount, (unsigned long)associations);
}

- (void)addMetadata:(VIMVideoMetadata *)metadata toVideoAsset:(VIMVideoAsset *)videoAsset withCompletionBlock:(AddMetadataCompletionBlock)completionBlock
{
    NSParameterAssert(metadata && videoAsset);
    
    VIMVideoUploadTask *task = (VIMVideoUploadTask *)[self taskForIdentifier:videoAsset.identifier];
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

- (void)configureTaskBlocks:(VIMVideoUploadTask *)task forAsset:(VIMVideoAsset *)asset
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

- (void)resumeIfAllowed
{
    if (self.isSuspendedByUser == NO)
    {
        [super resume];
        
        [self notifyOfStateChange];
    }
}

#pragma mark - Overrides

- (NSUserDefaults *)taskQueueDefaults
{
    NSString *sharedContainerID = self.sessionManager.session.configuration.sharedContainerIdentifier;
    if (sharedContainerID)
    {
        return [[NSUserDefaults alloc] initWithSuiteName:sharedContainerID];
    }
    else
    {
        return [NSUserDefaults standardUserDefaults];
    }
}

- (void)prepareTask:(VIMTask *)task
{
    if (!task)
    {
        return;
    }
    
    VIMVideoUploadTask *uploadTask = (VIMVideoUploadTask *)task;
    
    if (uploadTask.sessionManager == nil)
    {
        uploadTask.sessionManager = self.sessionManager;
    }
}

- (void)suspend
{
    [super suspend];

    self.suspendedByUser = YES;
    
    [self notifyOfStateChange];
}

- (void)resume
{
    if ([[VIMReachability sharedInstance] isNetworkReachable] == NO)
    {
        return;
    }
    
    if ([[VIMReachability sharedInstance] isOn3G] && self.isCellularUploadEnabled == NO)
    {
        return;
    }
        
    [super resume];

    self.suspendedByUser = NO;
    
    [self notifyOfStateChange];
}

#pragma mark - Accessor Overrides

- (void)setSuspendedByUser:(BOOL)suspendedByUser
{
    if (_suspendedByUser != suspendedByUser)
    {
        _suspendedByUser = suspendedByUser;
        
        [self saveCommonSettings];
    }
}

- (void)setCellularUploadEnabled:(BOOL)cellularUploadEnabled
{
    if (_cellularUploadEnabled != cellularUploadEnabled)
    {
        _cellularUploadEnabled = cellularUploadEnabled;
        
        [self saveCommonSettings];

        if ([[VIMReachability sharedInstance] isOn3G])
        {
            if (_cellularUploadEnabled)
            {
                [self resumeIfAllowed];
            }
            else
            {
                [super suspend];
                
                [self notifyOfStateChange];
            }
        }
    }
}

#pragma mark - Notifications

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineNotification:) name:VIMReachabilityStatusChangeOnlineNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlineNotification:) name:VIMReachabilityStatusChangeOfflineNotification object:nil];
}

- (void)onlineNotification:(NSNotification *)notification
{
    if ([[VIMReachability sharedInstance] isOn3G])
    {
        if (self.cellularUploadEnabled)
        {
            [self resumeIfAllowed];
        }
        else
        {
            [super suspend];
            
            [self notifyOfStateChange];
        }
    }
    else if ([[VIMReachability sharedInstance] isOnWiFi])
    {
        [self resumeIfAllowed];
    }
}

- (void)offlineNotification:(NSNotification *)notification
{
    [super suspend];
    
    [self notifyOfStateChange];
}

- (void)notifyOfStateChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMUploadTaskQueue_DidSuspendOrResumeNotification object:nil];
    });
}

#pragma mark - Archival

// Note: We use the same archive key for both app and extension
// because the values being archived apply to both app and extension
// (they're global settings) [AH]

- (void)loadCommonSettings
{
    NSUserDefaults *sharedDefaults = [self taskQueueDefaults];
    
    NSDictionary *dictionary = [sharedDefaults objectForKey:(NSString *)ArchiveKey];
    
    self.cellularUploadEnabled = [dictionary[CellularEnabledKey] boolValue];
    self.suspendedByUser = [dictionary[SuspendedByUserKey] boolValue];
}

- (void)saveCommonSettings
{
    NSUserDefaults *sharedDefaults = [self taskQueueDefaults];

    NSDictionary *dictionary = @{CellularEnabledKey : @(self.isCellularUploadEnabled), SuspendedByUserKey : @(self.isSuspendedByUser)};
    
    [sharedDefaults setObject:dictionary forKey:(NSString *)ArchiveKey];
    [sharedDefaults synchronize];
}

@end
