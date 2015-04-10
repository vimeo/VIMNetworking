//
//  VIMTaskQueue.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 15/08/2013.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMTaskOld;
@class VIMCache;
@protocol VIMTaskQueueDelegate;

@interface VIMTaskQueueOld : NSObject

@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, assign, readonly) NSUInteger numberOfTasks;
@property (nonatomic, assign, readonly) NSUInteger numberOfTasksInQueue;
@property (nonatomic, weak) id<VIMTaskQueueDelegate> delegate;

- (instancetype)initWithName:(NSString *)name;

- (NSArray *)tasks;
- (NSArray *)tasksInQueue;

- (void)addTask:(VIMTaskOld *)task;
- (void)removeTask:(VIMTaskOld *)task;
- (void)retryTask:(VIMTaskOld *)task;
- (void)pause;
- (void)resume;
- (BOOL)isPaused;

- (void)setCache:(VIMCache *)cache;
- (void)save;

- (void)reload;

@end

@protocol VIMTaskQueueDelegate <NSObject>

@optional

- (void)taskQueue:(VIMTaskQueueOld *)taskQueue task:(VIMTaskOld *)task didCompleteWithError:(NSError *)error;

@end
