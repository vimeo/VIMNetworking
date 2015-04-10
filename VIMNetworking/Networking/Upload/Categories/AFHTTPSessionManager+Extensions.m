//
//  AFHTTPSessionManager.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@implementation AFHTTPSessionManager (Extensions)

- (BOOL)cancelTaskWithIdentifier:(NSUInteger)taskIdentifier
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

- (NSURLSessionTask *)taskForIdentifier:(NSUInteger)taskIdentifier
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

- (NSURLSessionUploadTask *)uploadTaskForIdentifier:(NSUInteger)taskIdentifier
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

- (NSURLSessionDownloadTask *)downloadTaskForIdentifier:(NSUInteger)taskIdentifier
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

- (NSProgress *)uploadProgressForTaskWithIdentifier:(NSUInteger)taskIdentifier
{
    NSURLSessionUploadTask *task = [self uploadTaskForIdentifier:taskIdentifier];
    if (task)
    {
        return [self uploadProgressForTask:task];
    }
    
    return nil;
}

- (BOOL)taskExistsForIdentifier:(NSUInteger)taskIdentifier
{
    NSURLSessionTask *task = [self taskForIdentifier:taskIdentifier];
    
    return task != nil;
}

@end
