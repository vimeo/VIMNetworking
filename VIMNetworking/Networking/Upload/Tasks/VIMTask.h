//
//  Task.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *VIMTaskErrorDomain;

typedef NS_ENUM(NSInteger, VIMTaskState)
{
    TaskStateNone,
    TaskStateExecuting,
    TaskStateSuspended,
    TaskStateCancelled,
    TaskStateFinished
};

@class VIMTask;

@protocol VIMTaskDelegate <NSObject>

@optional
- (void)taskDidStart:(VIMTask *)task;
- (void)task:(VIMTask *)task didStartSubtask:(VIMTask *)subtask;
- (void)task:(VIMTask *)task didCompleteSubtask:(VIMTask *)subtask;

@required
- (void)taskDidComplete:(VIMTask *)task;

@end

@interface VIMTask : NSObject <NSCoding>

@property (nonatomic, weak) id<VIMTaskDelegate> delegate;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) VIMTaskState state;

- (void)resume;
- (void)suspend;
- (void)cancel;
- (BOOL)didSucceed;

@end
