//
//  UploadTask.m
//  Pegasus
//
//  Created by Alfred Hanssen on 2/27/15.
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

#import "VIMUploadTask.h"
#import "VIMCreateTicketTask.h"
#import "VIMUploadFileTask.h"
#import "VIMActivateTicketTask.h"
#import "VIMAddMetadataTask.h"

static const NSString *VIMUploadTaskName = @"UPLOAD";

static void *UploadProgressContext = &UploadProgressContext;

@interface VIMUploadTask () <VIMTaskDelegate>

@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, strong, readwrite) AVURLAsset *URLAsset;
@property (nonatomic, assign) BOOL canUploadFromSource;

@property (nonatomic, assign, readwrite) VIMUploadState uploadState;

@property (nonatomic, strong) VIMTask *currentTask;

@property (nonatomic, copy) NSString *localURI;
@property (nonatomic, copy) NSString *uploadURI;
@property (nonatomic, copy) NSString *activationURI;
@property (nonatomic, copy, readwrite) NSString *videoURI;

@end

@implementation VIMUploadTask

- (void)dealloc
{
    [self removeUploadProgressObserverIfNecessary];
 
//    self.uploadState = VIMUploadState_None;
    _uploadStateBlock = nil;

    if (self.uploadProgressBlock)
    {
        self.uploadProgressBlock(0);
        _uploadProgressBlock = nil;
    }
    
    _uploadCompletionBlock = nil;
}

- (instancetype)initWithPHAsset:(PHAsset *)phAsset
{
    NSParameterAssert(phAsset);
    
    self = [self init];
    if (self)
    {
        _phAsset = phAsset;
        self.identifier = phAsset.localIdentifier;
    }
    
    return self;
}

- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset canUploadFromSource:(BOOL)canUploadFromSource
{
    NSParameterAssert(URLAsset);
    
    self = [self init];
    if (self)
    {
        _URLAsset = URLAsset;
        _canUploadFromSource = canUploadFromSource;
        
        self.identifier = [URLAsset.URL absoluteString];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMUploadTaskName;
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
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        ((VIMNetworkTask *)self.currentTask).sessionManager = self.sessionManager;
        self.currentTask.delegate = self;
        
        [self.currentTask resume];
        
        [self addUploadProgressObserver];

        return;
    }
    
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    self.uploadState = VIMUploadState_CreatingRecord;
    
    VIMCreateTicketTask *task = nil;
    if (self.phAsset)
    {
        task = [[VIMCreateTicketTask alloc] initWithPHAsset:self.phAsset];
    }
    else
    {
        task = [[VIMCreateTicketTask alloc] initWithURLAsset:self.URLAsset canUploadFromSource:self.canUploadFromSource];
    }
    
    task.sessionManager = self.sessionManager;
    task.delegate = self;
    [task resume];
    
    self.currentTask = task;
}

- (void)suspend
{
    self.state = TaskStateSuspended;
 
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ suspended", self.name]];

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
            [self progress:task];
            
            [self taskDidComplete];
        }
    }
    else
    {
        self.error = task.error;

        [self progress:task];
        
        [self taskDidComplete];
    }
}

- (void)metadataTaskDidComplete:(VIMAddMetadataTask *)task
{
    if (![task didSucceed])
    {
        self.error = task.error;
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
    if (self.uploadCompletionBlock)
    {
        self.uploadCompletionBlock(self.videoURI, self.error);
    }

    if (self.state == TaskStateCancelled)
    {
        self.uploadState = VIMUploadState_None;
    }
    else
    {
        self.state = TaskStateFinished;

        if ([self didSucceed])
        {
            self.uploadState = VIMUploadState_Succeeded;
        }
        else
        {
            if (self.error.code != NSURLErrorCancelled)
            {
                self.uploadState = VIMUploadState_Failed;
            }
            else
            {
                self.uploadState = VIMUploadState_None;
            }
        }
    }

    self.currentTask = nil;
    
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
                    double progress = strongSelf.state == TaskStateSuspended ? 0 : ((NSProgress *)object).fractionCompleted;
                    strongSelf.uploadProgressBlock(progress);
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
        self.currentTask = [coder decodeObjectForKey:NSStringFromSelector(@selector(currentTask))];
        self.localURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(localURI))];
        self.uploadURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(uploadURI))];
        self.activationURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(activationURI))];
        self.videoURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoURI))];
        self.uploadState = [coder decodeIntegerForKey:NSStringFromSelector(@selector(uploadState))];
        self.canUploadFromSource = [coder decodeBoolForKey:NSStringFromSelector(@selector(canUploadFromSource))];
        self.videoMetadata = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoMetadata))];
        
        NSString *assetLocalIdentifier = [coder decodeObjectForKey:@"assetLocalIdentifier"];
        if (assetLocalIdentifier)
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:options];
            self.phAsset = [result firstObject];
            
            NSAssert(self.phAsset, @"Must be able to unarchive PHAsset");
        }
        
        NSURL *URL = [coder decodeObjectForKey:@"URL"];
        if (URL)
        {
            self.URLAsset = [AVURLAsset assetWithURL:URL];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.currentTask forKey:NSStringFromSelector(@selector(currentTask))];
    [coder encodeObject:self.localURI forKey:NSStringFromSelector(@selector(localURI))];
    [coder encodeObject:self.uploadURI forKey:NSStringFromSelector(@selector(uploadURI))];
    [coder encodeObject:self.activationURI forKey:NSStringFromSelector(@selector(activationURI))];
    [coder encodeObject:self.videoURI forKey:NSStringFromSelector(@selector(videoURI))];
    [coder encodeInteger:self.uploadState forKey:NSStringFromSelector(@selector(uploadState))];
    [coder encodeBool:self.canUploadFromSource forKey:NSStringFromSelector(@selector(canUploadFromSource))];
    [coder encodeObject:self.videoMetadata forKey:NSStringFromSelector(@selector(videoMetadata))];

    if (self.phAsset)
    {
        [coder encodeObject:self.phAsset.localIdentifier forKey:@"assetLocalIdentifier"];
    }
    else if (self.URLAsset)
    {
        [coder encodeObject:self.URLAsset.URL forKey:@"URL"];
    }
}

@end
