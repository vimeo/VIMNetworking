//
//  VIMTaskOperation.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 12/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOperation.h"
#import "VIMTaskOld.h"

static void *VIMTaskOperation_TaskStatusContext = &VIMTaskOperation_TaskStatusContext;
static void *VIMTaskOperation_TaskProgressContext = &VIMTaskOperation_TaskProgressContext;

@interface VIMTaskOperation ()
{
    BOOL _executing;
    BOOL _finished;
    
    BOOL _taskObserversAdded;
}

@property (nonatomic, strong, readwrite) VIMTaskOld *task;

@end

@implementation VIMTaskOperation

- (void)dealloc
{
    if(_taskObserversAdded)
    {
        [self.task removeObserver:self forKeyPath:@"status"];
        [self.task removeObserver:self forKeyPath:@"progress"];
        
        _taskObserversAdded = NO;
    }
}

- (instancetype)initWithTask:(VIMTaskOld *)task
{
    self = [super init];
    if(self)
    {
        _task = task;
        
        _executing = NO;
        _finished = NO;
    }
    
    return self;
}

- (void)start
{
    // Check for cancellation before launching the task
    
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    
    // Add observers
    
    [self.task addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:VIMTaskOperation_TaskStatusContext];
    [self.task addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:VIMTaskOperation_TaskProgressContext];
    _taskObserversAdded = YES;
    
    // Start task on new thread
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.task start];
    });
    
    _executing = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == VIMTaskOperation_TaskStatusContext)
    {
        if(self.task.status == VIMTaskStatus_Finished)
        {
            [self completeOperation];
        }
    }
    else if (context == VIMTaskOperation_TaskProgressContext)
    {
        
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)cancel
{
    [self.task stop];
    
    [super cancel];
}

@end
