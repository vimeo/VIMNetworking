//
//  UploadTask.m
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMVideoUploadTask.h"
#import "VIMCreateTicketTask.h"
#import "VIMUploadFileTask.h"
#import "VIMActivateTicketTask.h"
#import "VIMAddMetadataTask.h"

static const NSString *VIMVideoUploadTaskName = @"UPLOAD";

static void *UploadProgressContext = &UploadProgressContext;

@interface VIMVideoUploadTask () <VIMTaskDelegate>

@property (nonatomic, assign, readwrite) VIMUploadState uploadState;

@property (nonatomic, strong) VIMTask *currentTask;

@property (nonatomic, copy) NSString *localURI;
@property (nonatomic, copy) NSString *uploadURI;
@property (nonatomic, copy) NSString *activationURI;
@property (nonatomic, copy, readwrite) NSString *videoURI;

@end

@implementation VIMVideoUploadTask

- (void)dealloc
{
    [self removeUploadProgressObserverIfNecessary];
 
    self.uploadState = VIMUploadState_None;
    _uploadStateBlock = nil;

    if (self.uploadProgressBlock)
    {
        self.uploadProgressBlock(0);
        _uploadProgressBlock = nil;
    }
    
    _uploadCompletionBlock = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMVideoUploadTaskName;
        _uploadState = VIMUploadState_Enqueued;
    }
    
    return self;
}

#pragma mark - Public API

- (void)resume
{
    NSAssert(self.state != TaskStateFinished, @"Cannot start a finished task");

    if ((self.state == TaskStateExecuting || self.state == TaskStateSuspended) && self.currentTask)
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        ((VIMNetworkTask *)self.currentTask).sessionManager = self.sessionManager;
        self.currentTask.delegate = self;
        
        [self.currentTask resume];
        
        [self addUploadProgressObserver];

        return;
    }
    
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    self.uploadState = VIMUploadState_CreatingRecord;
    
    VIMCreateTicketTask *task = nil;
    if (self.phAsset)
    {
        task = [[VIMCreateTicketTask alloc] initWithPHAsset:self.phAsset];
    }
    else
    {
        task = [[VIMCreateTicketTask alloc] initWithURLAsset:self.URLAsset];
    }
    
    task.sessionManager = self.sessionManager;
    task.delegate = self;
    [task resume];
    
    self.currentTask = task;
}

- (void)suspend
{
    self.state = TaskStateSuspended;
 
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ suspended", self.name]];

    [self removeUploadProgressObserverIfNecessary];

    if (self.uploadProgressBlock)
    {
        self.uploadProgressBlock(0);
    }

    [self.currentTask suspend];
}

- (void)cancel
{    
    self.state = TaskStateCancelled;
    
    self.error = [NSError errorWithDomain:(NSString *)VIMTaskErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Cancelled"}];
    
    [self removeUploadProgressObserverIfNecessary];
    
    if (self.uploadProgressBlock)
    {
        self.uploadProgressBlock(0);
    }

    if (self.uploadStateBlock)
    {
        self.uploadStateBlock(VIMUploadState_None);
    }

    [self.currentTask cancel];
}

- (BOOL)didSucceed
{
    return self.videoURI != nil;
}

#pragma mark - Accessor Overrides

- (void)setUploadState:(VIMUploadState)uploadState
{
    if (_uploadState != uploadState)
    {
        _uploadState = uploadState;
        
        if (self.uploadStateBlock)
        {
            self.uploadStateBlock(uploadState);
        }
    }
}

#pragma mark - Task Delegate

- (void)taskDidStart:(VIMTask *)task
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(task:didStartSubtask:)])
    {
        [self.delegate task:self didStartSubtask:task];
    }
}

- (void)taskDidComplete:(VIMTask *)task
{
    if ([task isKindOfClass:[VIMCreateTicketTask class]])
    {
        VIMCreateTicketTask *currentTask = (VIMCreateTicketTask *)task;
        [self createRecordTaskDidComplete:currentTask];
    }
    else if ([task isKindOfClass:[VIMUploadFileTask class]])
    {
        VIMUploadFileTask *currentTask = (VIMUploadFileTask *)task;
        [self uploadFileTaskDidComplete:currentTask];
    }
    else if ([task isKindOfClass:[VIMActivateTicketTask class]])
    {
        VIMActivateTicketTask *currentTask = (VIMActivateTicketTask *)task;
        [self activateRecordTaskDidComplete:currentTask];
    }
    else if ([task isKindOfClass:[VIMAddMetadataTask class]])
    {
        VIMAddMetadataTask *currentTask = (VIMAddMetadataTask *)task;
        [self metadataTaskDidComplete:currentTask];
    }
}

#pragma mark - Private API

- (void)createRecordTaskDidComplete:(VIMCreateTicketTask *)task;
{
    if ([task didSucceed])
    {
        self.localURI = task.localURI;
        self.uploadURI = task.uploadURI;
        self.activationURI = task.activationURI;
        self.uploadState = VIMUploadState_UploadingFile;

        [self progress:task];

        VIMUploadFileTask *newTask = [[VIMUploadFileTask alloc] initWithSource:self.localURI destination:self.uploadURI];
        self.currentTask = newTask;

        newTask.sessionManager = self.sessionManager;
        newTask.delegate = self;
        [newTask resume];
        
        [self addUploadProgressObserver];
    }
    else
    {
        self.error = task.error;
        self.uploadState = VIMUploadState_Failed;
   
        [self progress:task];

        [self taskDidComplete];
    }
}

- (void)uploadFileTaskDidComplete:(VIMUploadFileTask *)task;
{
    [self removeUploadProgressObserverIfNecessary];
        
    if ([task didSucceed])
    {
        self.uploadState = VIMUploadState_ActivatingRecord;

        [self progress:task];

        VIMActivateTicketTask *newTask = [[VIMActivateTicketTask alloc] initWithActivationURI:self.activationURI];
        self.currentTask = newTask;

        newTask.sessionManager = self.sessionManager;
        newTask.delegate = self;
        [newTask resume];
    }
    else
    {
        self.error = task.error;
        self.uploadState = VIMUploadState_Failed;
   
        [self progress:task];

        [self taskDidComplete];
    }
}

- (void)activateRecordTaskDidComplete:(VIMActivateTicketTask *)task
{
    if ([task didSucceed])
    {
        self.videoURI = task.videoURI;

        if (self.videoMetadata)
        {
            self.uploadState = VIMUploadState_AddingMetadata;
            
            [self progress:task];
            
            VIMAddMetadataTask *newTask = [[VIMAddMetadataTask alloc] initWithVideoURI:self.videoURI metadata:self.videoMetadata];
            self.currentTask = newTask;
            
            newTask.sessionManager = self.sessionManager;
            newTask.delegate = self;
            [newTask resume];
        }
        else
        {
            self.uploadState = VIMUploadState_Succeeded;

            [self progress:task];

            [self taskDidComplete];
        }
    }
    else
    {
        self.error = task.error;
        self.uploadState = VIMUploadState_Failed;
    
        [self progress:task];
        
        [self taskDidComplete];
    }
}

- (void)metadataTaskDidComplete:(VIMAddMetadataTask *)task
{
    if ([task didSucceed])
    {
        self.uploadState = VIMUploadState_Succeeded;
    }
    else
    {
        self.error = task.error;
        self.uploadState = VIMUploadState_Failed;
    }
    
    [self progress:task];
    
    [self taskDidComplete];
}

- (void)progress:(VIMTask *)subtask
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(task:didCompleteSubtask:)])
    {
        [self.delegate task:self didCompleteSubtask:subtask];
    }
}

- (void)taskDidComplete
{
    if (self.state != TaskStateCancelled)
    {
        self.state = TaskStateFinished;
        self.currentTask = nil;
        self.uploadState = VIMUploadState_None;
    }
    
    if (self.uploadCompletionBlock)
    {
        self.uploadCompletionBlock(self.videoURI, self.error);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidComplete:)])
    {
        [self.delegate taskDidComplete:self];
    }
}

#pragma mark - Observers

- (void)addUploadProgressObserver
{
    if (self.currentTask == nil || ![self.currentTask isKindOfClass:[VIMUploadFileTask class]])
    {
        return;
    }

    VIMUploadFileTask *task = (VIMUploadFileTask *)self.currentTask;

    [task.uploadProgress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];
}

- (void)removeUploadProgressObserverIfNecessary
{
    VIMUploadFileTask *task = (VIMUploadFileTask *)self.currentTask;
    if ([task isKindOfClass:[VIMUploadFileTask class]] && task.uploadProgress)
    {
        @try
        {
            [task.uploadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:UploadProgressContext];
        }
        @catch (NSException *exception)
        {
            NSLog(@"Exception removing observer: %@", exception);
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadProgressContext)
    {
        if ([object isKindOfClass:[NSProgress class]] && [keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))])
        {
            __weak typeof(self) welf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong typeof(welf) strongSelf = welf;
                if (strongSelf == nil)
                {
                    return;
                }
                
                if (strongSelf.uploadProgressBlock)
                {
                    strongSelf.uploadProgressBlock(((NSProgress *)object).fractionCompleted);
                }
            });
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.currentTask = [coder decodeObjectForKey:@"currentTask"];
        self.uploadURI = [coder decodeObjectForKey:@"uploadURI"];
        self.localURI = [coder decodeObjectForKey:@"localURI"];
        self.activationURI = [coder decodeObjectForKey:@"activationURI"];
        self.videoURI = [coder decodeObjectForKey:@"videoURI"];
        self.uploadState = [coder decodeIntegerForKey:@"uploadState"];        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.currentTask forKey:@"currentTask"];
    [coder encodeObject:self.localURI forKey:@"localURI"];
    [coder encodeObject:self.uploadURI forKey:@"uploadURI"];
    [coder encodeObject:self.activationURI forKey:@"activationURI"];
    [coder encodeObject:self.videoURI forKey:@"videoURI"];
    [coder encodeInteger:self.uploadState forKey:@"uploadState"];    
}

@end
