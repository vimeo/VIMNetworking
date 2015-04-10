//
//  VIMAFNetUploadTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/18/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMUploadVideoTask.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"
#import "VIMNetworking.h"
#import "VIMUploadRecord.h"
#import "VIMTaskDebugger.h"
#import "VIMSessionManager.h"

NSString *const VIMUploadVideoTaskFractionCompletedNotification = @"fractionCompleted";

static void *VIMUploadVideoTask_progressContext = &VIMUploadVideoTask_progressContext;

@interface VIMUploadVideoTask () <NSCoding>

@property (nonatomic, weak) NSURLSessionTask *currentTask;

@property (nonatomic, assign) unsigned long long uploadedContentLength;
@property (nonatomic, assign) unsigned long long uploadStartOffset;
@property (nonatomic, assign) unsigned long long uploadFileSize;

@property (nonatomic, strong) NSProgress *currentProgress;

@end

@implementation VIMUploadVideoTask

- (void)dealloc
{
    [self setupWithProgress:nil];
}

- (id)init
{
	self = [super init];
	if(self)
	{
        _uploadedContentLength = 0;
        _uploadStartOffset = 0;
        _uploadFileSize = 0;
	}
	
	return self;
}

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];

    if (self.filePath == nil || [self.filePath length] == 0)
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: self.filePath is nil"];
        
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCompleteUploadErrorCode message:@"self.filePath is nil"];

        if (self.completionBlock)
        {
            self.completionBlock(self.error);
        }
        
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager new];
    
    if(![fileManager fileExistsAtPath:self.filePath])
    {
        NSString *tmpDir = [[VIMSession sharedSession] appGroupTmpPath];

        // Workaround: fix for iOS simulator path bug in XCode6 Beta
        NSString *filename = [self.filePath lastPathComponent];
        NSString *fixedFilePath = [tmpDir stringByAppendingPathComponent:filename];
        if([fileManager fileExistsAtPath:fixedFilePath])
        {
            self.filePath = fixedFilePath;
        }
        else
        {
            [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: file does not exist"];

            self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:FailedUploadErrorCode message:@"Upload Failed: File doesn't exist."];
            
            if (self.completionBlock)
            {
                self.completionBlock(self.error);
            }

            return;
        }
    }

    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
    unsigned long long fileSize = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
    self.uploadFileSize = fileSize;
    
    __weak typeof(self) weakSelf = self;
    [self checkRunningInBackgroundWithCompletionBlock:^(BOOL runningInBackground) {
        if(runningInBackground)
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"Already running in background"];

            return;
        }
        
        [weakSelf updateStatusFromServerWithCompletionBlock:^(NSError *error) {
            
            if ( error )
            {
                [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failed:updateStatusFromServerWithCompletionBlock error %@", error]];

                weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:FailedUploadErrorCode baseError:error];
                
                if (weakSelf.completionBlock)
                {
                    weakSelf.completionBlock(weakSelf.error);
                }
                
                return;
            }
            
            [weakSelf upload];
        }];
    }];
}

- (void)pause
{
    [super pause];

    if(self.currentTask)
        [self.currentTask suspend];
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
        [self.currentTask cancel];
        self.currentTask = nil;
    }
    
    [super stop];
}

- (void)cancel
{
    if(self.currentTask)
        [self.currentTask cancel];

    [super cancel];
}

#pragma mark - Internal methods

- (void)checkRunningInBackgroundWithCompletionBlock:(void (^)(BOOL runningInBackground))completionBlock
{
    if([NSThread isMainThread] == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkRunningInBackgroundWithCompletionBlock:completionBlock];
        });
        
        return;
    }
    
    if(self.currentTask != nil)
    {
        if(completionBlock)
            completionBlock(YES);
        
        return;
    }
    
    VIMSessionManager *manager = nil;
    if(self.isExtensionUpload)
        manager = [VIMSessionManager sharedExtensionManager];
    else
        manager = [VIMSessionManager sharedAppManager];

//    NSString *sessionID = manager.session.configuration.identifier;
//    [VIMNetworkTask debugLog:[NSString stringWithFormat:@"VIMUploadVideoTask (%@): checkRunningInBackground", self.taskID]];
    
    __weak typeof(self) weakSelf = self;
    [manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        for(NSURLSessionUploadTask *uploadTask in uploadTasks)
        {
            if([uploadTask.originalRequest.URL.absoluteString isEqualToString:self.uploadRecord.uploadURISecure])
            {
                weakSelf.currentTask = uploadTask;
                
                NSProgress *progress = [manager uploadProgressForTask:uploadTask];
                [self setupWithProgress:progress];
                
                [manager setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
                    
                    if(task == uploadTask)
                    {
                        [weakSelf uploadCompletedWithResponse:task.response responseObject:nil error:error];
                    }
                }];
                
                if(completionBlock)
                    completionBlock(YES);

                return;
            }
        }
        
        if(completionBlock)
            completionBlock(NO);
    }];
}

- (void)upload
{
    __weak typeof(self) weakSelf = self;
    [self checkRunningInBackgroundWithCompletionBlock:^(BOOL runningInBackground) {
        if(runningInBackground)
            return;
 
        [weakSelf doUpload];
    }];
}

- (void)doUpload
{
    if(self.uploadedContentLength == self.uploadFileSize)
    {
        // File already uploaded
        if(self.completionBlock)
            self.completionBlock(nil);
        
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Already uploaded"];
        
        return;
    }
    
    if(self.uploadedContentLength > self.uploadFileSize)
    {
        NSLog(@"Upload can't be resumed: Corrupt Upload: uploadedContentLength = %llu, uploadFileSize = %llu", self.uploadedContentLength, self.uploadFileSize);
        
        self.uploadedContentLength = 0;
    }

    VIMSessionManager *manager = nil;
    if(self.isExtensionUpload)
        manager = [VIMSessionManager sharedExtensionManager];
    else
        manager = [VIMSessionManager sharedAppManager];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[self.filePath lastPathComponent] forKey:@"file_name"];
    
    NSError* error = nil;
    
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"PUT" URLString:self.uploadRecord.uploadURISecure parameters:parameters error:&error];

    [request setValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
    
    NSProgress *progress;
    NSURLSessionUploadTask *uploadTask;
    
    // Background sessions do not support streamed request
    
    self.uploadStartOffset = 0;
    [request setValue:[NSString stringWithFormat:@"%llu", self.uploadFileSize] forHTTPHeaderField:@"Content-Length"];

    __weak typeof(self) weakSelf = self;
    uploadTask = [manager uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:self.filePath] progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        [weakSelf uploadCompletedWithResponse:response responseObject:responseObject error:error];
        
    }];
    
    [self setupWithProgress:progress];
    
    self.currentTask = uploadTask;
    
    [uploadTask resume];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == VIMUploadVideoTask_progressContext)
    {
        if([object isKindOfClass:[NSProgress class]])
        {
            if (self.progressBlock)
            {
                NSProgress *progress = (NSProgress *)object;

                double initialProgress = self.uploadStartOffset/(double)self.uploadFileSize;
                double totalProgress = initialProgress + (1.0f - initialProgress) * progress.fractionCompleted;
                
                self.progressBlock(totalProgress);
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)uploadCompletedWithResponse:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error
{
    [self setupWithProgress:nil];
    
    if(error)
    {
        if(self.isCancelled)
        {
            [VIMTaskDebugger debugLogWithClass:[self class] message:@"Upload cancelled"];
        }
        else
        {
            [VIMTaskDebugger debugLogWithClass:[self class] message:@"Upload failed"];
        }
        
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:FailedUploadErrorCode baseError:error];
        
        if(self.completionBlock)
        {
            self.completionBlock(self.error);
        }
    }
    else
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Upload success"];
        
        if(self.completionBlock)
        {
            self.completionBlock(nil);
        }
    }
}

#pragma mark - Update status from server

- (void)updateStatusFromServerWithCompletionBlock:(void (^)(NSError *error))completionBlock
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.requestSerializer setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [manager.requestSerializer setValue:@"bytes */*" forHTTPHeaderField:@"Content-Range"];
    
    __weak typeof(self) weakSelf = self;
    [manager PUT:self.uploadRecord.uploadURISecure parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
		
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        
        NSString *rangeStr = [response.allHeaderFields objectForKey:@"Range"];
        
        [weakSelf updateStatusWithRangeString:rangeStr];
        
        if(completionBlock)
            completionBlock(nil);
        
		
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        
        weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:FailedUploadErrorCode baseError:error];

        if (response.statusCode == 308)
        {
			// 308 HTTP response code = Resume Incomplete
			
            NSString *rangeStr = [response.allHeaderFields objectForKey:@"Range"];
            [weakSelf updateStatusWithRangeString:rangeStr];

            if(completionBlock)
                completionBlock(nil); // TODO: pass error or no??? [AH]

            return;
        }
        
        if(completionBlock)
            completionBlock(weakSelf.error);
	}];
}

#pragma mark - Helper methods

- (void)updateStatusWithRangeString:(NSString *)rangeStr
{
    unsigned long long bytesUploaded = [self getContentLengthFromRangeString:rangeStr];
    
    self.uploadedContentLength = bytesUploaded;
}

- (unsigned long long)getContentLengthFromRangeString:(NSString *)rangeStr
{
    if ([rangeStr hasPrefix:@"bytes"])
    {
        rangeStr = [rangeStr stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
        
        NSArray *bytes = [rangeStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
        if ([bytes count] == 2)
        {
            //long long contentOffset = [bytes[0] longLongValue];
            
            unsigned long long contentLength = [bytes[1] longLongValue];
            return contentLength;
        }
    }
    
    return 0;
}

- (void)setupWithProgress:(NSProgress *)progress
{
    if (self.currentProgress)
    {
        [self.currentProgress removeObserver:self forKeyPath:VIMUploadVideoTaskFractionCompletedNotification context:VIMUploadVideoTask_progressContext];
        self.currentProgress = nil;
    }
    
    if (progress)
    {
        [progress addObserver:self
                   forKeyPath:VIMUploadVideoTaskFractionCompletedNotification
                      options:NSKeyValueObservingOptionNew
                      context:VIMUploadVideoTask_progressContext];
        self.currentProgress = progress;
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.uploadRecord = [aDecoder decodeObjectForKey:@"uploadRecord"];
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
        self.isExtensionUpload = [aDecoder decodeBoolForKey:@"isExtensionUpload"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.uploadRecord forKey:@"uploadRecord"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    [aCoder encodeBool:self.isExtensionUpload forKey:@"isExtensionUpload"];
}

@end
