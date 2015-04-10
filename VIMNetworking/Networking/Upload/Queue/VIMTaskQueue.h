//
//  UploadQueue.h
//  Hermes
//
//  Created by Hanssen, Alfie on 2/13/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMTask;

@interface VIMTaskQueue : NSObject

@property (nonatomic, assign, readonly) NSInteger taskCount;

- (instancetype)initWithName:(NSString *)name;

- (void)addTasks:(NSArray *)tasks;
- (void)addTask:(VIMTask *)task;
- (void)cancelAllTasks;
- (void)cancelTask:(VIMTask *)task;
- (void)suspend;
- (void)resume;
- (BOOL)isSuspended;

- (void)prepareTask:(VIMTask *)task;
- (VIMTask *)taskForIdentifier:(NSString *)identifier;

// Optionally override to return shared container defaults [AH]
- (NSUserDefaults *)taskQueueDefaults;

@end
