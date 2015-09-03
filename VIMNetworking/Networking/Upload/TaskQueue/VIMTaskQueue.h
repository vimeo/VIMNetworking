//
//  UploadQueue.h
//  Pegasus
//
//  Created by Hanssen, Alfie on 2/13/15.
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

#import <Foundation/Foundation.h>
#import "VIMTaskQueueArchiverProtocol.h"

extern NSString *const __nonnull VIMTaskQueueTaskFailedNotification;
extern NSString *const __nonnull VIMTaskQueueTaskSucceededNotification;

@class VIMTask;

@interface VIMTaskQueue : NSObject

@property (nonatomic, strong, readonly, nullable) NSString *name;
@property (nonatomic, strong, readonly, nullable) id<VIMTaskQueueArchiverProtocol> archiver;
@property (nonatomic, assign, readonly) NSInteger taskCount;

- (nullable instancetype)initWithName:(nonnull NSString *)name archiver:(nonnull id<VIMTaskQueueArchiverProtocol>)archiver;

- (void)addTasks:(nonnull NSArray *)tasks;
- (void)addTask:(nonnull VIMTask *)task;
- (void)cancelAllTasks;
- (void)cancelTask:(nonnull VIMTask *)task;
- (void)cancelTaskForIdentifier:(nonnull NSString *)identifier;
- (nullable VIMTask *)taskForIdentifier:(nonnull NSString *)identifier;

- (void)suspend;
- (void)resume;
- (BOOL)isSuspended;

// Optional subclass overrides

- (void)prepareTask:(nonnull VIMTask *)task; // Override to modiy task before it is started [AH]

@end
