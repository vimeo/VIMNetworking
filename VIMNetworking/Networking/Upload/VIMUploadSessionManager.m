//
//  UploadSessionManager.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/29/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMUploadSessionManager.h"
#import "VIMUploadDebugger.h"
#import "NSURLSessionConfiguration+Extensions.h"

// TODO: Eliminate dependency here, can these be injected? [AH]
#import "VIMSession.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"

@implementation VIMUploadSessionManager

+ (instancetype)sharedAppInstance
{
    static VIMUploadSessionManager *sharedAppInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[[VIMSession sharedSession] backgroundSessionIdentifierApp] sharedContainerID:[[VIMSession sharedSession] sharedContainerID]];
        
        sharedAppInstance = [[self alloc] initWithSessionConfiguration:configuration];

    });
    
    return sharedAppInstance;
}

+ (instancetype)sharedExtensionInstance
{
    static VIMUploadSessionManager *sharedExtensionInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[[VIMSession sharedSession] backgroundSessionIdentifierExtension] sharedContainerID:[[VIMSession sharedSession] sharedContainerID]];
        
        sharedExtensionInstance = [[self alloc] initWithSessionConfiguration:configuration];
        
    });
    
    return sharedExtensionInstance;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSURL *url = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)

    {
        self.requestSerializer = [VIMRequestSerializer serializerWithSession:[VIMSession sharedSession]];
        self.responseSerializer = [VIMResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        
        [self setupSessionDidBecomeInvalid];
    }

    return self;
}

#pragma mark - Public API

- (void)setupBlocks
{
    [self setupDownloadTaskDidFinish];
    [self setupTaskDidComplete];
    [self setupDidFinishEventsForBackgroundURLSession];
}

- (void)callBackgroundEventsCompletionHandler
{
    if (self.completionHandler)
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.session.configuration.identifier message:@"calling completionHandler"];
        
        self.completionHandler();
        self.completionHandler = nil;
    }
}

#pragma mark - Private API

- (void)setupSessionDidBecomeInvalid
{
    [self setSessionDidBecomeInvalidBlock:^(NSURLSession *session, NSError *error) {
        
        [VIMUploadDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionDidBecomeInvalid"];
        
    }];
}

- (void)setupDownloadTaskDidFinish
{
    __weak typeof(self) welf = self;
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {

        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return nil;
        }
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManager:downloadTask:didFinishWithLocation:)])
        {
            [strongSelf.delegate sessionManager:strongSelf downloadTask:downloadTask didFinishWithLocation:location];
        }
        
        return nil;
    }];
}

- (void)setupTaskDidComplete
{
    __weak typeof(self) welf = self;
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        
        [VIMUploadDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionTaskDidComplete"];

        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManager:taskDidComplete:)])
        {
            [strongSelf.delegate sessionManager:strongSelf taskDidComplete:task];
        }
        
    }];
}

- (void)setupDidFinishEventsForBackgroundURLSession
{
    __weak typeof(self) welf = self;
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        
        [VIMUploadDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionDidFinishBackgroundEvents"];

        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        BOOL shouldCallCompletionHandler = YES;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManagerShouldCallBackgroundEventsCompletionHandler:)])
        {
            shouldCallCompletionHandler = [strongSelf.delegate sessionManagerShouldCallBackgroundEventsCompletionHandler:strongSelf];
        }
        
        if (shouldCallCompletionHandler)
        {
            [strongSelf callBackgroundEventsCompletionHandler];
        }
        
    }];
}

@end
