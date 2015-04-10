//
//  MetadataTask.m
//  Hermes
//
//  Created by Hanssen, Alfie on 3/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMAddMetadataTask.h"
#import "VIMVideoMetadata.h"

static const NSString *VIMMetadataTaskName = @"METADATA";
static const NSString *VIMMetadataTaskErrorDomain = @"VIMMetadataTaskErrorDomain";

@interface VIMAddMetadataTask ()

@property (nonatomic, strong) NSString *videoURI;
@property (nonatomic, strong) VIMVideoMetadata *videoMetadata;

@property (nonatomic, assign) BOOL success;

@end

@implementation VIMAddMetadataTask

- (instancetype)initWithVideoURI:(NSString *)videoURI metadata:(VIMVideoMetadata *)videoMetadata
{
    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMMetadataTaskName;

        _videoURI = videoURI;
        _videoMetadata = videoMetadata;
    }

    return self;
}

#pragma mark - Public API

- (void)resume
{
    NSAssert(self.state != TaskStateFinished, @"Cannot start a finished task");
    
    if ((self.state == TaskStateExecuting || self.state == TaskStateSuspended) && [self.sessionManager taskExistsForIdentifier:self.backgroundTaskIdentifier])
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];
        
        self.state = TaskStateExecuting;
        
        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
        
        return;
    }
    
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];
    
    self.state = TaskStateExecuting;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if ([self.videoMetadata.videoTitle length] > 0)
    {
        parameters[@"name"] = self.videoMetadata.videoTitle;
    }
    
    if ([self.videoMetadata.videoDescription length] > 0)
    {
        parameters[@"description"] = self.videoMetadata.videoDescription;
    }

    if ([self.videoMetadata.videoPrivacy length] > 0)
    {
        parameters[@"privacy"] = @{@"view" : self.videoMetadata.videoPrivacy};
    }
    
    NSURL *fullURL = [NSURL URLWithString:self.videoURI relativeToURL:self.sessionManager.baseURL];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PATCH" URLString:[fullURL absoluteString] parameters:parameters error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMMetadataTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to serialize request."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:NULL destination:nil completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;
    
    self.sessionManager.delegate = self;
    [self.sessionManager setupBlocks];
    
    [self taskDidStart];
    
    [task resume];
}

- (BOOL)didSucceed
{
    return self.success;
}

#pragma mark - UploadSessionManager Delegate

- (void)sessionManager:(VIMUploadSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    self.backgroundTaskIdentifier = NSNotFound;
    sessionManager.delegate = nil;
    
    if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
    {
        return;
    }
    
    if (task.error)
    {
        self.error = task.error;
        
        [self taskDidComplete];
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)task.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMMetadataTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    self.success = YES;
    
    [self taskDidComplete];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.videoMetadata = [coder decodeObjectForKey:@"videoMetadata"];
        self.success = [coder decodeBoolForKey:@"success"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.videoMetadata forKey:@"videoMetadata"];
    [coder encodeBool:self.success forKey:@"success"];
}

@end
