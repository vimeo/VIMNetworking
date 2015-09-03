//
//  CreateRecordTask.m
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

#import "VIMCreateTicketTask.h"
#import "VIMTempFileMaker.h"
#include "AVAsset+Filesize.h"
#import "PHAsset+Filesize.h"
#import "NSError+VIMUpload.h"

static const NSString *RecordCreationPath = @"/me/videos";
static const NSString *VIMCreateRecordTaskName = @"CREATE";

@interface VIMCreateTicketTask ()

@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, strong, readwrite) AVURLAsset *URLAsset;
@property (nonatomic, assign) BOOL canUploadFromSource;

@property (nonatomic, strong) NSDictionary *responseDictionary;

@property (nonatomic, copy, readwrite) NSString *localURI;
@property (nonatomic, copy, readwrite) NSString *uploadURI;
@property (nonatomic, copy, readwrite) NSString *activationURI;

@end

@implementation VIMCreateTicketTask

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
        self.name = (NSString *)VIMCreateRecordTaskName;
    }
    
    return self;
}

#pragma mark - Public API

- (void)resume
{
    NSAssert(self.state != TaskStateFinished, @"Cannot start a finished task");

    if ((self.state == TaskStateExecuting || self.state == TaskStateSuspended) && [self.sessionManager taskExistsForIdentifier:self.backgroundTaskIdentifier])
    {
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
                
        return;
    }
    
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    NSURL *fullURL = [NSURL URLWithString:(NSString *)RecordCreationPath relativeToURL:self.sessionManager.baseURL];
    
    uint64_t filesize = 0;
    
    if (self.URLAsset)
    {
        filesize = [self.URLAsset calculateFilesize];
    }
    else if (self.phAsset)
    {
        filesize = [self.phAsset calculateFilesize];
    }
    
    NSDictionary *parameters = @{@"type" : @"streaming", @"size" : @(filesize)};    
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"POST" URLString:[fullURL absoluteString] parameters:parameters error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:error.code userInfo:error.userInfo];
        
        [self taskDidComplete];
        
        return;
    }
        
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:NULL destination:nil completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;
    
    self.sessionManager.delegate = self;
    [self.sessionManager setupBlocks];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(taskDidStart:)])
    {
        [self.delegate taskDidStart:self];
    }
    
    [task resume];
}

- (void)cancel
{
    [self deleteLocalFile];

    [super cancel];
}

- (BOOL)didSucceed
{
    return self.localURI && self.uploadURI && self.activationURI;
}

#pragma mark - Private API

- (void)deleteLocalFile
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (self.localURI && [fileManager fileExistsAtPath:self.localURI])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:self.localURI error:&error];
        if (error)
        {
            [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ error deleting local file %@", self.name, error]];
        }
    }
}

- (void)taskDidComplete
{
    [super taskDidComplete];
    
    [self.sessionManager callBackgroundEventsCompletionHandler];
}

#pragma mark - VIMNetworkTaskSessionManager Delegate

- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishWithLocation:(NSURL *)location
{
    if (downloadTask.taskIdentifier != self.backgroundTaskIdentifier)
    {
        return;
    }

    if (downloadTask.error)
    {
        self.error = [NSError errorWithError:downloadTask.error domain:VIMCreateRecordTaskErrorDomain URLResponse:downloadTask.response];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)downloadTask.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        return;
    }
    
    if (location == nil)
    {
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"No location provided."}];
        
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    if (data == nil)
    {
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"No file at location."}];
        
        return;
    }
    
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:error.code userInfo:error.userInfo];
        
        return;
    }
    
    self.responseDictionary = dictionary;
}

- (void)sessionManager:(VIMNetworkTaskSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    if (task.taskIdentifier != self.backgroundTaskIdentifier)
    {
        return;
    }
    
    self.backgroundTaskIdentifier = NSNotFound;
    sessionManager.delegate = nil;
    
    if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
    {
        // TODO: do we need to delete the local file when suspended? [AH]

        return;
    }

    if (self.error)
    {
        [self taskDidComplete];
        
        return;
    }

    if (task.error)
    {
        self.error = [NSError errorWithError:task.error domain:VIMCreateRecordTaskErrorDomain URLResponse:task.response];
        
        [self taskDidComplete];
        
        return;
    }

    NSString *uploadURI = [self.responseDictionary objectForKey:@"upload_link_secure"];
    NSString *activationURI = [self.responseDictionary objectForKey:@"complete_uri"];
    if (uploadURI == nil || activationURI == nil)
    {
        NSString *description = [NSString stringWithFormat:@"Reponse did not include upload_link_secure or complete_uri. (%@)", [self.responseDictionary description]];
        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : description}];

        [self taskDidComplete];
        
        return;
    }

    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:@"COPY started"];

    [self tempFileWithCompletionBlock:^(NSString *path, NSError *error) {
        
        if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
        {
            // TODO: do we need to delete the local file when suspended? [AH]
            
            return;
        }
        
        if (error)
        {
            [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:@"COPY failed"];

            [[[NSFileManager alloc] init] removeItemAtPath:path error:NULL];
            
            self.error = error;
            
            [self taskDidComplete];
            
            return;
        }
        
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:@"COPY succeeded"];

        self.localURI = path;
        self.uploadURI = uploadURI;
        self.activationURI = activationURI;
        
        [self taskDidComplete];
        
    }];
}

- (BOOL)sessionManagerShouldCallBackgroundEventsCompletionHandler:(VIMNetworkTaskSessionManager *)sessionManager
{
    return NO;
}

- (void)tempFileWithCompletionBlock:(TempFileCompletionBlock)completionBlock
{
    VIMTempFileMaker *fileMaker = [[VIMTempFileMaker alloc] initWithSharedContainerIdentifier:self.sessionManager.session.configuration.sharedContainerIdentifier];
    
    if (self.URLAsset)
    {
        if (self.canUploadFromSource)
        {
            if (completionBlock)
            {
                completionBlock([self.URLAsset.URL absoluteString], nil);
            }
        }
        else
        {
            [fileMaker tempFileFromURLAsset:self.URLAsset completionBlock:completionBlock];
        }
    }
    else
    {
        [fileMaker tempFileFromPHAsset:self.phAsset completionBlock:completionBlock];
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.localURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(localURI))];
        self.uploadURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(uploadURI))];
        self.activationURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(activationURI))];
        self.responseDictionary = [coder decodeObjectForKey:NSStringFromSelector(@selector(responseDictionary))];
        self.canUploadFromSource = [coder decodeBoolForKey:NSStringFromSelector(@selector(canUploadFromSource))];
        
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

    [coder encodeObject:self.localURI forKey:NSStringFromSelector(@selector(localURI))];
    [coder encodeObject:self.uploadURI forKey:NSStringFromSelector(@selector(uploadURI))];
    [coder encodeObject:self.activationURI forKey:NSStringFromSelector(@selector(activationURI))];
    [coder encodeObject:self.responseDictionary forKey:NSStringFromSelector(@selector(responseDictionary))];
    [coder encodeBool:self.canUploadFromSource forKey:NSStringFromSelector(@selector(canUploadFromSource))];

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
