//
//  UploadFileTask.m
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMUploadFileTask.h"

static const NSString *VIMUploadFileTaskName = @"FILE_UPLOAD";
static const NSString *VIMUploadFileTaskErrorDomain = @"VIMUploadFileTaskErrorDomain";

@interface VIMUploadFileTask ()

@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *destination;
@property (nonatomic, strong, readwrite) NSProgress *uploadProgress;

@property (nonatomic, assign) BOOL success;

@end

@implementation VIMUploadFileTask

- (void)dealloc
{
    self.uploadProgress.completedUnitCount = 0;
    _uploadProgress = nil;
}

- (instancetype)initWithSource:(NSString *)source destination:(NSString *)destination
{
    NSParameterAssert(source != nil && destination != nil);

    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMUploadFileTaskName;
        
        _source = [source copy];
        _destination = [destination copy];
    }
    
    return self;
}

#pragma mark - Public API

- (void)resume
{
    NSAssert(self.state != TaskStateFinished, @"Cannot start a finished task");

    if ((self.state == TaskStateExecuting || self.state == TaskStateSuspended) && [self.sessionManager taskExistsForIdentifier:self.backgroundTaskIdentifier])
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        self.uploadProgress = [self.sessionManager uploadProgressForTaskWithIdentifier:self.backgroundTaskIdentifier];
        
        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
        
        return;
    }

    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    if (![[NSFileManager defaultManager] fileExistsAtPath:self.source])
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Source file does not exist."}];
        
        [self taskDidComplete];

        return;
    }
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PUT" URLString:self.destination parameters:nil error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to serialize request."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSURL *sourceURL = [NSURL fileURLWithPath:self.source];
    
    NSNumber *size = nil;
    BOOL success = [sourceURL getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
    if (!success)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to get file size."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    [request setValue:[NSString stringWithFormat:@"%llu", [size unsignedLongLongValue]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
    
    NSProgress *progress = nil;
    NSURLSessionUploadTask *task = [self.sessionManager uploadTaskWithRequest:request fromFile:sourceURL progress:&progress completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;

    self.uploadProgress = progress;

    self.sessionManager.delegate = self;
    [self.sessionManager setupBlocks];

    [self taskDidStart];

    [task resume];
}

- (BOOL)didSucceed
{
    return self.success;
}

#pragma mark - Private API

- (void)taskDidComplete
{
    [self deleteLocalFile];
    
    self.uploadProgress.completedUnitCount = 0;
 
    [super taskDidComplete];
}

- (void)deleteLocalFile
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (self.source && [fileManager fileExistsAtPath:self.source])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:self.source error:&error];
        if (error)
        {
            [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ error deleting local file %@", self.name, error]];
        }
    }
}

#pragma mark - UploadSessionManager Delegate

- (void)sessionManager:(VIMUploadSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    self.backgroundTaskIdentifier = NSNotFound;
    sessionManager.delegate = nil;

    if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
    {
        return;
    }

    if (task.error)
    {
        self.error = task.error;
        
        [self taskDidComplete];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)task.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    self.success = YES;
    
    [self taskDidComplete];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.source = [coder decodeObjectForKey:@"source"];
        self.destination = [coder decodeObjectForKey:@"destination"];
        self.success = [coder decodeBoolForKey:@"success"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:self.source forKey:@"source"];
    [coder encodeObject:self.destination forKey:@"destination"];
    [coder encodeBool:self.success forKey:@"success"];
}

@end
