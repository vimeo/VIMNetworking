//
//  ActivateRecordTask.m
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMActivateTicketTask.h"

static const NSString *VIMActivateRecordTaskName = @"ACTIVATE";
static const NSString *VIMActivateRecordTaskErrorDomain = @"VIMActivateRecordTaskErrorDomain";

@interface VIMActivateTicketTask ()

@property (nonatomic, copy) NSString *activationURI;
@property (nonatomic, copy, readwrite) NSString *videoURI;

@end

@implementation VIMActivateTicketTask

- (instancetype)initWithActivationURI:(NSString *)activationURI
{
    NSParameterAssert(activationURI != nil);

    self = [super init];
    if (self)
    {
        self.name = (NSString *)VIMActivateRecordTaskName;
        
        _activationURI = [activationURI copy];
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
    
    NSURL *fullURL = [NSURL URLWithString:self.activationURI relativeToURL:self.sessionManager.baseURL];
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"DELETE" URLString:[fullURL absoluteString] parameters:nil error:&error];
    if (error)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMActivateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to serialize request."}];
        
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
    return self.videoURI != nil;
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
        self.error = [NSError errorWithDomain:(NSString *)VIMActivateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        [self taskDidComplete];
        
        return;
    }

    NSString *location = [[HTTPResponse allHeaderFields] valueForKey:@"Location"];
    if (!location)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMActivateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Location header not provided."}];
        
        [self taskDidComplete];
        
        return;
    }
    
    self.videoURI = location;

    [self taskDidComplete];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.videoURI = [coder decodeObjectForKey:@"videoURI"];
        self.activationURI = [coder decodeObjectForKey:@"activationURI"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:self.videoURI forKey:@"videoURI"];
    [coder encodeObject:self.activationURI forKey:@"activationURI"];
}

@end
