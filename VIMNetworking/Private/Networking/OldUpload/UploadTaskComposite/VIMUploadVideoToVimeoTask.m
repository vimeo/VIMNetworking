//
//  VIMAFNetUploadVideoToVimeoTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMUploadVideoToVimeoTask.h"

#import "VIMCreateUploadRecordTask.h"
#import "VIMCopyFileToTempTask.h"
#import "VIMRemoveFileTask.h"
#import "VIMUploadVideoTask.h"
#import "VIMVideoMetadataTask.h"
#import "VIMCompleteUploadTask.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "VIMUploadRecord.h"
#import "VIMTaskDebugger.h"
#import "NSError+BaseError.h"
#import "VIMUploadErrorDomain.h"

@interface VIMUploadVideoToVimeoTask ()

@property (nonatomic, copy) NSString *tempFilePath;
@property (nonatomic, strong) VIMUploadRecord *uploadRecord;
@property (nonatomic, copy, readwrite) NSString *videoURI;

@property (nonatomic, strong) NSMutableArray *pendingTasks;
@property (nonatomic, strong) NSMutableArray *completedTasks;
@property (nonatomic, strong) VIMTaskOld *currentTask;

@end

@implementation VIMUploadVideoToVimeoTask

- (id)init
{
	self = [super init];
	if (self)
	{
        _pendingTasks = [NSMutableArray array];
        _completedTasks = [NSMutableArray array];

        [self addTask:[[VIMCreateUploadRecordTask alloc] init]];
	}
	
	return self;
}

- (void)start
{
//    [VIMNetworkTask debugLogWithClass:[self class] message:@"Start"];

    if(self.status == VIMTaskStatus_Finished && self.error)
        self.status = VIMTaskStatus_Waiting;
    
    self.error = nil;
    self.isCancelled = NO;
    self.currentTask = nil;
    
    if(self.videoURI)
    {
        // Already uploaded, just update meta data
        
        [self.pendingTasks removeAllObjects];
        [self addVideoMetaDataTask];
    }
    
    [self startNextTask];
}

- (void)pause
{
    [super pause];
    
    if(self.currentTask)
        [self.currentTask pause];
}

- (void)resume
{
    [super resume];
    
    if(self.currentTask)
        [self.currentTask resume];
}

- (void)stop
{
    if(self.currentTask)
    {
        [self.currentTask stop];
        self.currentTask = nil;
    }
    
    [super stop];
}

- (void)cancel
{
    if(self.currentTask)
    {
        [self.currentTask cancel];
        self.currentTask = nil;
    }
    
    [super cancel];

    // Make sure completion block is called on cancel
    if (self.completionBlock)
    {
        self.completionBlock(self.videoURI, self.isCancelled, self.error);
    }
}

- (void)startNextTask
{
    if(self.isCancelled)
        return;
    
    if (self.currentTask != nil)
    {
        [self.pendingTasks removeObject:self.currentTask];
        [self.completedTasks addObject:self.currentTask];
        self.currentTask = nil;
    }
    
    if(self.isPaused)
        return;
    
    if (self.pendingTasks.count > 0)
    {
        self.currentTask = [self.pendingTasks firstObject];
        if (self.currentTask != nil)
        {
            //NSLog(@"startNextTask: Starting %@", NSStringFromClass([self.currentTask class]));

            self.status = VIMTaskStatus_Progress;
            [self.currentTask start];
            
            return;
        }
    }
    
    self.status = VIMTaskStatus_Finished;
    
    if ( self.completionBlock )
    {
        self.completionBlock(self.videoURI, self.isCancelled, self.error);
    }
}

- (void)addTask:(VIMTaskOld *)task
{
    if(task == nil)
        return;

    [self configureTask:task];
    [self.pendingTasks addObject:task];
}

- (void)configureTask:(VIMTaskOld *)task
{
    if ( [task isKindOfClass:[VIMCreateUploadRecordTask class]] )
    {
        [self configureCreateUploadRecordTask:(VIMCreateUploadRecordTask *)task];
    }
    else if ( [task isKindOfClass:[VIMCopyFileToTempTask class]] )
    {
        [self configureCopyFileTask:(VIMCopyFileToTempTask *)task];
    }
    else if ( [task isKindOfClass:[VIMUploadVideoTask class]] )
    {
        [self configureUploadVideoTask:(VIMUploadVideoTask *)task];
    }
    else if ( [task isKindOfClass:[VIMCompleteUploadTask class]] )
    {
        [self configureCompleteVideoUploadTask:(VIMCompleteUploadTask *)task];
    }
    else if ( [task isKindOfClass:[VIMRemoveFileTask class]] )
    {
        [self configureRemoveFileTask:(VIMRemoveFileTask *)task];
    }
    else if ( [task isKindOfClass:[VIMVideoMetadataTask class]] )
    {
        [self configureVideoMetadataTask:(VIMVideoMetadataTask *)task];
    }
    else
    {
        NSAssert(YES, @"Task does not conform to a valid protocol.");
    }
}

- (void)addVideoMetaDataTask
{
    if(self.videoURI == nil)
        return;
    
    VIMVideoMetadataTask *videoMetadataTask = [[VIMVideoMetadataTask alloc] init];
    videoMetadataTask.videoName =  self.videoName;
    videoMetadataTask.videoURI = self.videoURI;
    videoMetadataTask.videoPrivacy = self.videoPrivacy;
    videoMetadataTask.videoDescription = self.videoDescription;
    
    [self addTask:videoMetadataTask];
    
    [self startNextTask];
}

- (void)configureCreateUploadRecordTask:(VIMCreateUploadRecordTask *)createRecordTask
{
    __weak typeof(self) weakSelf = self;
    __weak VIMCreateUploadRecordTask *weakCreateRecordTask = createRecordTask;
    
    [createRecordTask setCompletionBlock:^(NSError* error)
     {
         if (error)
         {
             [weakSelf finishWithError:error];
             return;
         }
         
         weakSelf.uploadRecord = weakCreateRecordTask.uploadRecord;
         
         VIMCopyFileToTempTask *copyFileTask = [[VIMCopyFileToTempTask alloc] init];
         
         copyFileTask.localAsset = weakSelf.localAsset;
         
         copyFileTask.exportPreset = weakSelf.videoQualityExportPreset;
         
         [weakSelf addTask:copyFileTask];
         
         [weakSelf startNextTask];

     }];
}

- (void)configureCopyFileTask:(VIMCopyFileToTempTask *)copyFileTask
{
    __weak typeof(self) weakSelf = self;
    [copyFileTask setCompletionBlock:^(NSString *tmpPath, NSError* error)
    {
        if (error)
        {
            [weakSelf finishWithError:error];
            return;
        }
        
        weakSelf.tempFilePath = tmpPath;
        
        VIMUploadVideoTask *uploadTask = [[VIMUploadVideoTask alloc] init];
        uploadTask.uploadRecord = weakSelf.uploadRecord;
        uploadTask.filePath = weakSelf.tempFilePath;
        uploadTask.isExtensionUpload = weakSelf.isExtensionUpload;

        [weakSelf addTask:uploadTask];
        
        [weakSelf startNextTask];
    }];
}

- (void)configureUploadVideoTask:(VIMUploadVideoTask *)uploadVideoTask
{
    __weak typeof(self) weakSelf = self;
    [uploadVideoTask setCompletionBlock:^(NSError* error)
    {
        if (error)
        {
            [weakSelf finishWithError:error];
            return;
        }

        VIMCompleteUploadTask *completeUploadTask = [[VIMCompleteUploadTask alloc] init];
        completeUploadTask.completeURI = weakSelf.uploadRecord.completeURI;

        [weakSelf addTask:completeUploadTask];

        [weakSelf startNextTask];
    }];

    [uploadVideoTask setProgressBlock:^(double fractionCompleted)
    {
        weakSelf.progress = fractionCompleted;
        
        if (weakSelf.progressBlock)
            weakSelf.progressBlock(weakSelf.progress);
    }];
}

- (void)configureCompleteVideoUploadTask:(VIMCompleteUploadTask *)completeUploadTask
{
    __weak typeof(self) weakSelf = self;
    [completeUploadTask setCompletionBlock:^(NSString* videoURI, NSError* error)
     {
         if (error)
         {
             [weakSelf finishWithError:error];
             return;
         }

         weakSelf.videoURI = videoURI;
         
         VIMRemoveFileTask *removeFileTask = [[VIMRemoveFileTask alloc] init];
         removeFileTask.filePath = weakSelf.tempFilePath;
         
         [weakSelf addTask:removeFileTask];
         
         [weakSelf startNextTask];
     }];
}

- (void)configureRemoveFileTask:(VIMRemoveFileTask *)removeFileTask
{
    __weak typeof(self) weakSelf = self;
    [removeFileTask setCompletionBlock:^(NSError* error)
     {
         if (error)
         {
             NSLog(@"Could not remove file, if its in the temp directory it will eventually be purged by the system.");
         }
         
         [weakSelf addVideoMetaDataTask];
     }];
}

- (void)configureVideoMetadataTask:(VIMVideoMetadataTask *)videoMetadataTask
{
    __weak typeof(self) weakSelf = self;
    [videoMetadataTask setCompletionBlock:^(NSError* error)
     {
         if (error)
         {
             [weakSelf finishWithError:error];
             return;
         }
         
         [weakSelf startNextTask];
     }];
}

- (void)finishWithError:(NSError *)error
{
    if (error)
    {
        self.error = error;
    }
    else
    {
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:GenericCompositeUploadTaskErrorCode message:nil];
    }
    
    self.status = VIMTaskStatus_Finished;
    
    if ( self.completionBlock )
    {
        self.completionBlock(self.videoURI, self.isCancelled, self.error);
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.pendingTasks = [NSMutableArray array];
        self.completedTasks = [NSMutableArray array];
        
        self.localAsset = [aDecoder decodeObjectForKey:@"localAsset"];
        self.videoName = [aDecoder decodeObjectForKey:@"videoName"];
        self.videoDescription = [aDecoder decodeObjectForKey:@"videoDescription"];
        self.videoObjectID = [aDecoder decodeObjectForKey:@"videoUniqueID"];
        self.videoPrivacy = [aDecoder decodeObjectForKey:@"videoPrivacy"];
        self.videoQualityExportPreset = [aDecoder decodeObjectForKey:@"exportPreset"];
        self.videoURI = [aDecoder decodeObjectForKey:@"videoURI"];
        self.tempFilePath = [aDecoder decodeObjectForKey:@"tmpFilePath"];
        self.uploadRecord = [aDecoder decodeObjectForKey:@"uploadRecord"];
        self.isExtensionUpload = [aDecoder decodeBoolForKey:@"isExtensionUpload"];
        
        NSArray *pendingTasks = [aDecoder decodeObjectForKey:@"pendingTasks"];
        if(pendingTasks)
        {
            for(VIMTaskOld *task in pendingTasks)
                [self addTask:task];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.localAsset forKey:@"localAsset"];
    [aCoder encodeObject:self.videoName forKey:@"videoName"];
    [aCoder encodeObject:self.videoDescription forKey:@"videoDescription"];
    [aCoder encodeObject:self.videoObjectID forKey:@"videoUniqueID"];
    [aCoder encodeObject:self.videoPrivacy forKey:@"videoPrivacy"];
    [aCoder encodeObject:self.videoQualityExportPreset forKey:@"exportPreset"];
    [aCoder encodeObject:self.videoURI forKey:@"videoURI"];
    [aCoder encodeObject:self.tempFilePath forKey:@"tmpFilePath"];
    [aCoder encodeObject:self.uploadRecord forKey:@"uploadRecord"];
    [aCoder encodeObject:[self.pendingTasks copy] forKey:@"pendingTasks"];
    [aCoder encodeBool:self.isExtensionUpload forKey:@"isExtensionUpload"];
}

@end
