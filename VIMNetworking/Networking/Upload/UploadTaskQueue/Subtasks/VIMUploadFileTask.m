//
//  UploadFileTask.m
//  Pegasus
//
//  Created by Alfred Hanssen on 2/27/15.
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

#import "VIMUploadFileTask.h"
#import <AVFoundation/AVFoundation.h>
#import "AVAsset+Filesize.h"
#import "NSError+VIMUpload.h"

static const NSString *VIMUploadFileTaskName = @"FILE_UPLOAD";

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
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        self.uploadProgress = [self.sessionManager uploadProgressForTaskWithIdentifier:self.backgroundTaskIdentifier];
        
        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
        
        return;
    }

    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    if (![[NSFileManager defaultManager] fileExistsAtPath:self.source])
    {
        self.error = [NSError errorWithDomain:VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Source file does not exist."}];
        
        [self taskDidComplete];

        return;
    }
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PUT" URLString:self.destination parameters:nil error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:VIMUploadFileTaskErrorDomain code:error.code userInfo:error.userInfo];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSURL *sourceURL = [NSURL fileURLWithPath:self.source];
    
    AVURLAsset *URLAsset = [AVURLAsset assetWithURL:sourceURL];
    CGFloat filesize = [URLAsset calculateFilesize];

    [request setValue:[NSString stringWithFormat:@"%.0f", filesize] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
    
    NSProgress *progress = nil;
    NSURLSessionUploadTask *task = [self.sessionManager uploadTaskWithRequest:request fromFile:sourceURL progress:&progress completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;

    self.uploadProgress = progress;

    self.sessionManager.delegate = self;
    [self.sessionManager setupBlocks];

    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidStart:)])
    {
        [self.delegate taskDidStart:self];
    }

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
            [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ error deleting local file %@", self.name, error]];
        }
    }
}

#pragma mark - VIMNetworkTaskSessionManager Delegate

- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    if (task.taskIdentifier != self.backgroundTaskIdentifier)
    {
        return;
    }

    self.backgroundTaskIdentifier = NSNotFound;
    sessionManager.delegate = nil;

    if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
    {
        return;
    }

    if (task.error)
    {
        self.error = [NSError errorWithError:task.error domain:VIMUploadFileTaskErrorDomain URLResponse:task.response];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)task.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:VIMUploadFileTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
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
        self.source = [coder decodeObjectForKey:NSStringFromSelector(@selector(source))];
        self.destination = [coder decodeObjectForKey:NSStringFromSelector(@selector(destination))];
        self.success = [coder decodeBoolForKey:NSStringFromSelector(@selector(success))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:self.source forKey:NSStringFromSelector(@selector(source))];
    [coder encodeObject:self.destination forKey:NSStringFromSelector(@selector(destination))];
    [coder encodeBool:self.success forKey:NSStringFromSelector(@selector(success))];
}

@end
