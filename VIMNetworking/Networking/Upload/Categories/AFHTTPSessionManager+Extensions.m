//
//  AFHTTPSessionManager.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
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

#import "AFHTTPSessionManager+Extensions.h"

@implementation AFHTTPSessionManager (Extensions)

- (BOOL)cancelTaskWithIdentifier:(NSInteger)taskIdentifier
{
    NSURLSessionTask *task = [self taskForIdentifier:taskIdentifier];
    
    [task cancel];
    
    return task != nil;
}

- (void)cancelAllTasks
{
    for (NSURLSessionTask *task in [self tasks])
    {
        [task cancel];
    }
}

- (NSURLSessionTask *)taskForIdentifier:(NSInteger)taskIdentifier
{
    for (NSURLSessionTask *task in [self tasks])
    {
        if (task.taskIdentifier == taskIdentifier)
        {
            return task;
        }
    }
    
    return nil;
}

- (NSURLSessionUploadTask *)uploadTaskForIdentifier:(NSInteger)taskIdentifier
{
    for (NSURLSessionUploadTask *task in [self uploadTasks])
    {
        if (task.taskIdentifier == taskIdentifier)
        {
            return task;
        }
    }
    
    return nil;
}

- (NSURLSessionDownloadTask *)downloadTaskForIdentifier:(NSInteger)taskIdentifier
{
    for (NSURLSessionDownloadTask *task in [self downloadTasks])
    {
        if (task.taskIdentifier == taskIdentifier)
        {
            return task;
        }
    }
    
    return nil;
}

- (NSProgress *)uploadProgressForTaskWithIdentifier:(NSInteger)taskIdentifier
{
    NSURLSessionUploadTask *task = [self uploadTaskForIdentifier:taskIdentifier];
    if (task)
    {
        return [self uploadProgressForTask:task];
    }
    
    return nil;
}

- (nullable NSProgress *)downloadProgressForTaskWithIdentifier:(NSInteger)taskIdentifier
{
    NSURLSessionDownloadTask *task = [self downloadTaskForIdentifier:taskIdentifier];
    if (task)
    {
        return [self downloadProgressForTask:task];
    }
    
    return nil;
}

- (BOOL)taskExistsForIdentifier:(NSInteger)taskIdentifier
{
    NSURLSessionTask *task = [self taskForIdentifier:taskIdentifier];
    
    return task != nil;
}

@end
