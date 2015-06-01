//
//  NetworkTask.m
//  Pegasus
//
//  Created by Hanssen, Alfie on 3/3/15.
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

#import "VIMNetworkTask.h"

@interface VIMNetworkTask ()

@end

@implementation VIMNetworkTask

#pragma mark - Public API

- (void)suspend
{
    self.state = TaskStateSuspended;
    
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ suspended", self.name]];
    
    NSURLSessionTask *task = [self.sessionManager taskForIdentifier:self.backgroundTaskIdentifier];
    if (task)
    {
        [task cancel];
    }
}

- (void)cancel
{
    self.state = TaskStateCancelled;
    
    self.error = [NSError errorWithDomain:(NSString *)VIMTaskErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Cancelled"}];
    
    NSURLSessionTask *task = [self.sessionManager taskForIdentifier:self.backgroundTaskIdentifier];
    if (task)
    {
        [task cancel];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidComplete:)])
    {
        [self.delegate taskDidComplete:self];
    }
}

#pragma mark - Private API

- (void)taskDidComplete
{
    self.state = TaskStateFinished;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidComplete:)])
    {
        [self.delegate taskDidComplete:self];
    }
}

#pragma mark - VIMNetworkTaskSessionManager Delegate

- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    NSAssert(NO, @"Subclasses must override.");
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.backgroundTaskIdentifier = [coder decodeIntegerForKey:NSStringFromSelector(@selector(backgroundTaskIdentifier))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeInteger:self.backgroundTaskIdentifier forKey:NSStringFromSelector(@selector(backgroundTaskIdentifier))];
}

@end
