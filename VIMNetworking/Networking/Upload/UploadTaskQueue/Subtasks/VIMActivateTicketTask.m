//
//  ActivateRecordTask.m
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

#import "VIMActivateTicketTask.h"
#import "NSError+VIMUpload.h"

static const NSString *VIMActivateRecordTaskName = @"ACTIVATE";

@interface VIMActivateTicketTask ()

@property (nonatomic, copy) NSString *activationURI;
@property (nonatomic, copy, readwrite) NSString *videoURI;

@end

@implementation VIMActivateTicketTask

- (instancetype)initWithActivationURI:(NSString *)activationURI
{
    NSParameterAssert(activationURI != nil);

    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMActivateRecordTaskName;
        
        _activationURI = [activationURI copy];
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
    
    NSURL *fullURL = [NSURL URLWithString:self.activationURI relativeToURL:self.sessionManager.baseURL];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"DELETE" URLString:[fullURL absoluteString] parameters:nil error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:VIMActivateRecordTaskErrorDomain code:error.code userInfo:error.userInfo];
        
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
    return self.videoURI != nil;
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
        self.error = [NSError errorWithError:task.error domain:VIMActivateRecordTaskErrorDomain URLResponse:task.response];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)task.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:VIMActivateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        [self taskDidComplete];
        
        return;
    }

    NSString *location = [[HTTPResponse allHeaderFields] valueForKey:@"Location"];
    if (!location)
    {
        self.error = [NSError errorWithDomain:VIMActivateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Location header not provided."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    self.videoURI = location;

    [self taskDidComplete];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.videoURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoURI))];
        self.activationURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(activationURI))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:self.videoURI forKey:NSStringFromSelector(@selector(videoURI))];
    [coder encodeObject:self.activationURI forKey:NSStringFromSelector(@selector(activationURI))];
}

@end
