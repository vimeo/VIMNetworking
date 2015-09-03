//
//  MetadataTask.m
//  Pegasus
//
//  Created by Hanssen, Alfie on 3/5/15.
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

#import "VIMAddMetadataTask.h"
#import "VIMVideoMetadata.h"
#import "NSError+VIMUpload.h"

static const NSString *VIMMetadataTaskName = @"METADATA";

@interface VIMAddMetadataTask ()

@property (nonatomic, strong) NSString *videoURI;
@property (nonatomic, strong) VIMVideoMetadata *videoMetadata;

@property (nonatomic, assign) BOOL success;

@end

@implementation VIMAddMetadataTask

- (instancetype)initWithVideoURI:(NSString *)videoURI metadata:(VIMVideoMetadata *)videoMetadata
{
    NSAssert(videoURI != nil, @"videoURI must not be nil");
    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMMetadataTaskName;

        _videoURI = videoURI;
        _videoMetadata = videoMetadata;
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
        
        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
        
        return;
    }
    
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];
    
    self.state = TaskStateExecuting;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if ([self.videoMetadata.videoTitle length] > 0)
    {
        parameters[@"name"] = self.videoMetadata.videoTitle;
    }
    
    if ([self.videoMetadata.videoDescription length] > 0)
    {
        parameters[@"description"] = self.videoMetadata.videoDescription;
    }

    if ([self.videoMetadata.videoPrivacy length] > 0)
    {
        parameters[@"privacy"] = @{@"view" : self.videoMetadata.videoPrivacy};
    }
    
    if ([[parameters allKeys] count] == 0) // There isn't any metadata to set...
    {
        self.success = YES;
        
        [self taskDidComplete];
        
        return;
    }
    
    if ([self.videoURI length] == 0)
    {
        self.error = [NSError errorWithDomain:VIMMetadataTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to add metadata to videoAsset, videoURI is nil."}];
        
        [self taskDidComplete];
        
        return;
    }

    NSURL *fullURL = [NSURL URLWithString:self.videoURI relativeToURL:self.sessionManager.baseURL];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PATCH" URLString:[fullURL absoluteString] parameters:parameters error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:VIMMetadataTaskErrorDomain code:error.code userInfo:error.userInfo];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:NULL destination:nil completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;
    
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
        self.error = [NSError errorWithDomain:VIMMetadataTaskErrorDomain code:task.error.code userInfo:task.error.userInfo];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)task.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:VIMMetadataTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
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
        self.videoMetadata = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoMetadata))];
        self.success = [coder decodeBoolForKey:NSStringFromSelector(@selector(success))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.videoMetadata forKey:NSStringFromSelector(@selector(videoMetadata))];
    [coder encodeBool:self.success forKey:NSStringFromSelector(@selector(success))];
}

@end
