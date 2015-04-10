//
//  NetworkTask.m
//  Hermes
//
//  Created by Hanssen, Alfie on 3/3/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"

@interface VIMNetworkTask ()

@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, strong, readwrite) AVURLAsset *URLAsset;

@end

@implementation VIMNetworkTask

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

- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset
{
    NSParameterAssert(URLAsset);
    
    self = [self init];
    if (self)
    {
        _URLAsset = URLAsset;
        self.identifier = [URLAsset.URL absoluteString];
    }
    
    return self;
}

#pragma mark - Public API

- (void)suspend
{
    self.state = TaskStateSuspended;
    
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ suspended", self.name]];
    
    NSURLSessionTask *task = [self.sessionManager taskForIdentifier:self.backgroundTaskIdentifier];
    if (task)
    {
        [task cancel];
    }
}

- (void)cancel
{
    self.state = TaskStateCancelled;
    
    self.error = [NSError errorWithDomain:(NSString *)VIMTaskErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Cancelled"}];
    
    NSURLSessionTask *task = [self.sessionManager taskForIdentifier:self.backgroundTaskIdentifier];
    if (task)
    {
        [task cancel];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidComplete:)])
    {
        [self.delegate taskDidComplete:self];
    }
}

#pragma mark - Private API

- (void)taskDidComplete
{
    self.state = TaskStateFinished;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidComplete:)])
    {
        [self.delegate taskDidComplete:self];
    }
}

- (void)taskDidStart
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidStart:)])
    {
        [self.delegate taskDidStart:self];
    }
}

#pragma mark - UploadSessionManager Delegate

- (void)sessionManager:(VIMUploadSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    NSAssert(NO, @"Subclasses must override.");
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.backgroundTaskIdentifier = [coder decodeIntegerForKey:@"backgroundTaskIdentifier"];
    
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
    
    [coder encodeInteger:self.backgroundTaskIdentifier forKey:@"backgroundTaskIdentifier"];

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
