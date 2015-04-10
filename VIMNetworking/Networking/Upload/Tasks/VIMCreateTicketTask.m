//
//  CreateRecordTask.m
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMCreateTicketTask.h"

static const NSString *RecordCreationPath = @"/me/videos";
static const NSString *VIMCreateRecordTaskName = @"CREATE";
static const NSString *VIMCreateRecordTaskErrorDomain = @"VIMCreateRecordTaskErrorDomain";

@interface VIMCreateTicketTask ()

@property (nonatomic, strong) NSDictionary *responseDictionary;

@property (nonatomic, copy, readwrite) NSString *localURI;
@property (nonatomic, copy, readwrite) NSString *uploadURI;
@property (nonatomic, copy, readwrite) NSString *activationURI;

@end

@implementation VIMCreateTicketTask

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
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ restarted", self.name]];

        self.state = TaskStateExecuting;

        self.sessionManager.delegate = self;
        [self.sessionManager setupBlocks];
                
        return;
    }
    
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"%@ started", self.name]];

    self.state = TaskStateExecuting;

    NSURL *fullURL = [NSURL URLWithString:(NSString *)RecordCreationPath relativeToURL:self.sessionManager.baseURL];
    
    NSError *error = nil;
    NSDictionary *parameters = @{@"type" : @"streaming"};
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"POST" URLString:[fullURL absoluteString] parameters:parameters error:&error];
    NSAssert(error == nil, @"Unable to construct request");
    
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:NULL destination:nil completionHandler:nil];
    self.backgroundTaskIdentifier = task.taskIdentifier;
    
    self.sessionManager.delegate = self;
    [self.sessionManager setupBlocks];
    
    [self taskDidStart];
    
    [task resume];
}

- (void)cancel
{
    // TODO: delete local file [AH]

    [super cancel];
}

- (BOOL)didSucceed
{
    return self.localURI && self.uploadURI && self.activationURI;
}

#pragma mark - Private API

- (void)taskDidComplete
{
    [super taskDidComplete];
    
    [self.sessionManager callBackgroundEventsCompletionHandler];
}

#pragma mark - UploadSessionManager Delegate

- (void)sessionManager:(VIMUploadSessionManager *)sessionManager downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishWithLocation:(NSURL *)location
{
    if (downloadTask.error)
    {
        self.error = downloadTask.error;
        
        return;
    }
    
    NSHTTPURLResponse *HTTPResponse = ((NSHTTPURLResponse *)downloadTask.response);
    if (HTTPResponse.statusCode < 200 || HTTPResponse.statusCode > 299)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid status code."}];
        
        return;
    }
    
    if (location == nil)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"No location provided."}];
        
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    if (data == nil)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"No file at location."}];
        
        return;
    }
    
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error)
    {
        self.error = error;
        
        return;
    }
    
    self.responseDictionary = dictionary;
}

- (void)sessionManager:(VIMUploadSessionManager *)sessionManager taskDidComplete:(NSURLSessionTask *)task
{
    self.backgroundTaskIdentifier = NSNotFound;
    sessionManager.delegate = nil;
    
    if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
    {
        // TODO: do we need to delete the local file when suspended? [AH]

        return;
    }
    
    NSString *uploadURI = [self.responseDictionary objectForKey:@"upload_link_secure"];
    NSString *activationURI = [self.responseDictionary objectForKey:@"complete_uri"];
    if (uploadURI == nil || activationURI == nil)
    {
        self.error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Reponse did not include upload_link_secure or complete_uri."}];
    }

    if (self.error)
    {
        [self taskDidComplete];

        return;
    }
    
    [self copyFileWithCompletionBlock:^(NSString *path, NSError *error) {
        
        if (self.state == TaskStateCancelled || self.state == TaskStateSuspended)
        {
            // TODO: do we need to delete the local file when suspended? [AH]
            
            return;
        }
        
        if (error)
        {
            self.error = error;
            
            [self taskDidComplete];
            
            return;
        }
        
        self.localURI = path;
        self.uploadURI = uploadURI;
        self.activationURI = activationURI;
        
        [self taskDidComplete];
        
    }];
}

- (BOOL)sessionManagerShouldCallBackgroundEventsCompletionHandler:(VIMUploadSessionManager *)sessionManager
{
    return NO;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.localURI = [coder decodeObjectForKey:@"localURI"];
        self.uploadURI = [coder decodeObjectForKey:@"uploadURI"];
        self.activationURI = [coder decodeObjectForKey:@"activationURI"];
        self.responseDictionary = [coder decodeObjectForKey:@"responseDictionary"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeObject:self.localURI forKey:@"localURI"];
    [coder encodeObject:self.uploadURI forKey:@"uploadURI"];
    [coder encodeObject:self.activationURI forKey:@"activationURI"];
    [coder encodeObject:self.responseDictionary forKey:@"responseDictionary"];
}

// TODO: Move copy out of this class [AH]

#pragma mark - File Copy

- (void)copyFileWithCompletionBlock:(void (^)(NSString *path, NSError *error))completionBlock
{
    [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:@"COPY: started"];

    if (self.URLAsset)
    {
        [self copyURLAsset:self.URLAsset withCompletionBlock:completionBlock];

        return;
    }
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    
    __weak typeof(self) welf = self;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.phAsset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (strongSelf.state == TaskStateCancelled)
        {
            return;
        }

        NSError *error = info[PHImageErrorKey];
        if (error)
        {
            [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"COPY: failed %@", error]];

            if (completionBlock)
            {
                completionBlock(nil, error);
            }

            return;
        }
        
        if (![asset isKindOfClass:[AVURLAsset class]])
        {
            self.error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot upload AVCompositions."}];

            [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"COPY: failed %@", self.error]];
            
            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        
        AVURLAsset *URLAsset = (AVURLAsset *)asset;
        [self copyURLAsset:URLAsset withCompletionBlock:completionBlock];
        
    }];
}

- (void)copyURLAsset:(AVURLAsset *)URLAsset withCompletionBlock:(void (^)(NSString *path, NSError *error))completionBlock
{
    NSString *extension = [URLAsset.URL pathExtension];
    NSURL *destinationURL = [self appGroupURLWithExtension:extension];
    
//    NSString *sourcePath = [URLAsset.URL path];
//    NSString *destinationPath = [destinationURL path];
    
    NSError *copyError = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:URLAsset.URL toURL:destinationURL error:&copyError];
//    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&copyError];
    
    if (success)
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:@"COPY: sucess"];
        
        if (completionBlock)
        {
            NSString *path = [destinationURL path];
            completionBlock(path, nil);
        }
    }
    else
    {
        [VIMUploadDebugger postLocalNotificationWithContext:self.sessionManager.session.configuration.identifier message:[NSString stringWithFormat:@"COPY: failed %@", copyError]];
        
        if (completionBlock)
        {
            completionBlock(nil, copyError);
        }
    }
}

- (NSURL *)appGroupURLWithExtension:(NSString *)extension
{
    NSString *basePath = [self appGroupExportsDirectory];
    
    NSString *filename = [[NSProcessInfo processInfo] globallyUniqueString];
    
    filename = [filename stringByAppendingPathExtension:extension];
    
    NSString *path = [basePath stringByAppendingPathComponent:filename];
    
    return [NSURL fileURLWithPath:path];
}

- (NSString *)appGroupExportsDirectory
{
    NSString *uploadsDirectoryName = @"uploads";
    
    NSURL *groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.sessionManager.session.configuration.sharedContainerIdentifier];
    if (groupURL == nil)
    {
        return [NSTemporaryDirectory() stringByAppendingPathComponent:uploadsDirectoryName];
    }
    
    NSString *groupPath = [[groupURL path] stringByAppendingPathComponent:uploadsDirectoryName];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:groupPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Unable to create export directory: %@", error);
        
        return [NSTemporaryDirectory() stringByAppendingPathComponent:uploadsDirectoryName];
    }
    
    return groupPath;
}

@end
