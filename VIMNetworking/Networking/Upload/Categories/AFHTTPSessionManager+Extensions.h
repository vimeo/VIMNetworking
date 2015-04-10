//
//  AFHTTPSessionManager.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@interface AFHTTPSessionManager (Extensions)

- (BOOL)cancelTaskWithIdentifier:(NSUInteger)taskIdentifier;
- (void)cancelAllTasks;

- (NSURLSessionTask *)taskForIdentifier:(NSUInteger)taskIdentifier;
- (NSURLSessionUploadTask *)uploadTaskForIdentifier:(NSUInteger)taskIdentifier;
- (NSURLSessionDownloadTask *)downloadTaskForIdentifier:(NSUInteger)taskIdentifier;

- (NSProgress *)uploadProgressForTaskWithIdentifier:(NSUInteger)taskIdentifier;
- (BOOL)taskExistsForIdentifier:(NSUInteger)taskIdentifier;

@end
