//
//  VIMTaskOperation.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 15/08/2013.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMTaskQueueOld.h"
#import "VIMTaskOld.h"
#import "VIMCache.h"
#import "VIMTaskOperation.h"

static void *kVIMTaskManager_TaskProgressObserverContext = &kVIMTaskManager_TaskProgressObserverContext;
static void *kVIMTaskManager_TaskStatusObserverContext = &kVIMTaskManager_TaskStatusObserverContext;

@interface VIMTaskQueueOld ()
{
    NSOperationQueue *_operationQueue;
    NSMutableArray *_tasks;
    
    VIMCache *_cache;
    
    dispatch_queue_t _processingQueue;
    
    NSString *_name;
}

@property (nonatomic, assign, readwrite) float progress;
@property (nonatomic, assign, readwrite) NSUInteger numberOfTasks;
@property (nonatomic, assign, readwrite) NSUInteger numberOfTasksInQueue;

@end

@implementation VIMTaskQueueOld

- (void)dealloc
{
    [self _doSave];
    
    for(VIMTaskOld *task in _tasks)
        [self _doRemoveTask:task];
}

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _name = [name copy];
        
        _processingQueue = dispatch_queue_create("com.vimeo.VIMTaskManager.processingQueue", DISPATCH_QUEUE_SERIAL);
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        _tasks = [NSMutableArray array];
        
        [self _load];
    }
    
    return self;
}

#pragma mark - Public API

- (void)addTask:(VIMTaskOld *)task
{
    if([_tasks containsObject:task])
        return;
    
    dispatch_async(_processingQueue, ^{
        [self _doAddTask:task];
        [self _save];
        [self _calculcateProgress];
    });
}

- (void)removeTask:(VIMTaskOld *)task
{
    if([_tasks containsObject:task] == NO)
        return;
    
    dispatch_async(_processingQueue, ^{
        [self _doRemoveTask:task];
        [self _save];
        [self _calculcateProgress];
    });
}

- (void)retryTask:(VIMTaskOld *)task
{
    if(task.status == VIMTaskStatus_Finished)
    {
        if(task.error || task.isCancelled)
        {
            [self removeTask:task];
            [task prepareForRetry];
            [self addTask:task];
        }
    }
}

- (void)pause
{
    if(_operationQueue.isSuspended)
        return;
    
    [_operationQueue setSuspended:YES];
    
    dispatch_async(_processingQueue, ^{
        
        for (VIMTaskOld *task in self.tasks)
            [task pause];
        
        [self _calculcateProgress];
    });
    
    [self _save];
}

- (void)resume
{
    if(_operationQueue.isSuspended == NO)
        return;
    
    [_operationQueue setSuspended:NO];
    
    dispatch_async(_processingQueue, ^{
        
        for (VIMTaskOld *task in self.tasks)
            [task resume];
        
        [self _calculcateProgress];
    });
    
    [self _save];
}

- (BOOL)isPaused
{
    return _operationQueue.isSuspended;
}

- (NSArray *)tasks
{
    return _tasks;
}

- (NSArray *)tasksInQueue
{
    NSMutableArray *unfinishedTask = [NSMutableArray array];
    
    NSArray *tasksCopy = [NSArray arrayWithArray:self.tasks];
    for (VIMTaskOld *task in tasksCopy)
    {
        if (task.status != VIMTaskStatus_Finished)
        {
            [unfinishedTask addObject:task];
        }
    }
    
    return unfinishedTask;
}

- (VIMTaskOld *)taskWithID:(NSString *)taskID
{
    NSArray *tasksCopy = [NSArray arrayWithArray:self.tasks];
    for (VIMTaskOld *task in tasksCopy)
    {
        if ([task.taskID isEqualToString:taskID])
        {
            return task;
        }
    }

    return nil;
}

- (void)setCache:(VIMCache *)cache
{
    if(_cache != cache)
    {
        if([_cache.name isEqualToString:cache.name] && [_cache.basePath isEqualToString:cache.basePath])
            return;
        
        _cache = cache;
        
        [self _load];
    }
}

#pragma mark - Internal methods

- (void)_doAddTask:(VIMTaskOld *)task
{
    [task addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:kVIMTaskManager_TaskProgressObserverContext];
    [task addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kVIMTaskManager_TaskStatusObserverContext];
    [_tasks addObject:task];
    
    if(task.status != VIMTaskStatus_Finished)
    {
        VIMTaskOperation *operation = [[VIMTaskOperation alloc] initWithTask:task];
        [_operationQueue addOperation:operation];
    }
    
    self.numberOfTasks = _tasks.count;
}

- (void)_doRemoveTask:(VIMTaskOld *)task
{
    VIMTaskOperation *operation = [self _getOperationForTask:task];
    if(operation)
        [operation cancel];
    
    if([_tasks containsObject:task])
    {
        [task removeObserver:self forKeyPath:@"progress" context:kVIMTaskManager_TaskProgressObserverContext];
        [task removeObserver:self forKeyPath:@"status" context:kVIMTaskManager_TaskStatusObserverContext];
        [_tasks removeObject:task];
    }
    
    self.numberOfTasks = _tasks.count;
}

- (VIMTaskOperation *)_getOperationForTask:(VIMTaskOld *)task
{
    for(VIMTaskOperation *operation in _operationQueue.operations)
    {
        if(operation.task == task)
            return operation;
    }
    
    return nil;
}

- (void)_calculcateProgress
{
    float new_progress = 0.0;
    int new_numberOfTasksInQueue = 0;
    
    if (self.tasks.count > 0)
    {
        new_numberOfTasksInQueue = 0;
        
        float sumProgress = 0;
        
        for(VIMTaskOld *task in self.tasks)
        {
            sumProgress += task.progress;
            
            if(task.status != VIMTaskStatus_Finished)
                new_numberOfTasksInQueue++;
        }
        
        new_progress = sumProgress / (float)self.tasks.count;
    }
    
    if(self.numberOfTasksInQueue != new_numberOfTasksInQueue)
        self.numberOfTasksInQueue = new_numberOfTasksInQueue;
    
    if(self.progress != new_progress)
        self.progress = new_progress;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == kVIMTaskManager_TaskProgressObserverContext)
    {
        dispatch_async(_processingQueue, ^{
            [self _calculcateProgress];
        });
    }
    else if(context == kVIMTaskManager_TaskStatusObserverContext)
    {
        dispatch_async(_processingQueue, ^{
            [self _calculcateProgress];
        });
        
        [self _save];
        
        VIMTaskOld *task = object;
        if (task.status == VIMTaskStatus_Finished)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(taskQueue:task:didCompleteWithError:)])
            {
                [self.delegate taskQueue:self task:task didCompleteWithError:task.error];
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)save
{
    [self _save];
}

- (void)reload
{
    [self _load];
}

#pragma mark - Save/Load

- (NSString *)saveKey
{
    return [NSString stringWithFormat:@"VIMTaskQueueSaveKey_%@", _name];
}

- (void)_doSave
{
    if(_cache == nil)
        return;

//    NSLog(@"VIMTaskQueue: _save %d tasks", (int)[_tasks count]);
    
    BOOL isPaused = [self isPaused];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:@"1" forKey:@"version"];
    [dict setObject:_tasks forKey:@"tasks"];
    [dict setObject:[NSNumber numberWithBool:isPaused] forKey:@"isPaused"];
    
    [_cache setObject:dict forKey:[self saveKey]];
}

- (void)_save
{
    if(_cache == nil)
        return;
	
	dispatch_async(_processingQueue, ^{
        [self _doSave];
	});
}

- (void)_load
{
    if(_cache == nil)
        return;
    
//    NSLog(@"VIMTaskManager(%@): _load", _name);
    
    id object = [_cache objectForKey:[self saveKey]];
    
    dispatch_async(_processingQueue, ^{
        
        NSArray *loadedTasks;
        BOOL isPaused;
        
        if([object isKindOfClass:[NSArray class]])
        {
            loadedTasks = object;
            isPaused = NO;
        }
        else
        {
            loadedTasks = [object objectForKey:@"tasks"];
            isPaused = [[object objectForKey:@"isPaused"] boolValue];
        }

        // Disabling this so no tasks will be removed while loading
        /*
		// Remove existing tasks

		[_operationQueue cancelAllOperations];
		
        NSArray *tasksToRemove = [NSArray arrayWithArray:_tasks];
		for (VIMTask *task in tasksToRemove)
        {
			[self _doRemoveTask:task];
		}
        */

        // Set pause state
        
        [_operationQueue setSuspended:isPaused];

		// Add new tasks
		
		if (loadedTasks)
		{
//			NSLog(@"VIMTaskQueue: Loaded %d tasks", (int)loadedTasks.count);
			
            int addedTaskCount = 0;
            
			for (VIMTaskOld *task in loadedTasks)
            {
                if([self taskWithID:task.taskID] == nil)
                {
                    [self _doAddTask:task];
                    addedTaskCount++;

//                    NSLog(@"VIMTaskQueue: Adding task (%@)", task.taskID);
                }
            }

//            NSLog(@"VIMTaskQueue: Added %d tasks", addedTaskCount);
		}
		
		[self _calculcateProgress];
	
	});
}

@end
