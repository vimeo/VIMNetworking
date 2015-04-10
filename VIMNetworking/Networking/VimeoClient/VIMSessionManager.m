//
//  VIMVimeoSessionManager.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMSessionManager.h"

#import "VIMNetworking.h"
#import "VIMResponseSerializer.h"
#import "VIMRequestSerializer.h"
#import "VIMSession.h"
#import "NSURLSessionConfiguration+Extensions.h"

@interface VIMSessionManager ()

@end

@implementation VIMSessionManager

- (instancetype)initWithDefaultSession
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    self = [super initWithBaseURL:baseURL];
    if(self)
    {
        [self initialSetup];
    }
    
    return self;
}

- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID
{
    return [self initWithBackgroundSessionID:sessionID sharedContainerID:nil];
}

- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID sharedContainerID:(NSString *)sharedContainerID
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:sessionID sharedContainerID:sharedContainerID];
    
    return [self initWithSessionConfiguration:configuration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    self = [super initWithBaseURL:baseURL sessionConfiguration:configuration];
    if (self)
    {
        [self initialSetup];
    }
    
    return self;
}

+ (VIMSessionManager *)sharedAppManager
{
    static dispatch_once_t onceTokenDefault;

    static VIMSessionManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[VIMSession sharedSession].configuration.backgroundSessionIdentifierApp sharedContainerID:nil]; // TODO: why no container ID here?

        NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
        _sharedInstance = [[self alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
    
        [_sharedInstance setSessionDidBecomeInvalidBlock:^(NSURLSession *session, NSError *error) {
            
            NSLog(@"Upload App Background Session became invalid! %@", error);
            
            // Session invalidated, Need to create new instance [KM]
            // Not so sure about this [AH]
            onceToken = onceTokenDefault;
        }];

    });
    
    return _sharedInstance;
}

+ (VIMSessionManager *)sharedExtensionManager
{
    static dispatch_once_t onceTokenDefault;

    static VIMSessionManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[VIMSession sharedSession].configuration.backgroundSessionIdentifierApp sharedContainerID:[VIMSession sharedSession].configuration.sharedContainerID];
        
        NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
        _sharedInstance = [[self alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];

        [_sharedInstance setSessionDidBecomeInvalidBlock:^(NSURLSession *session, NSError *error) {

            NSLog(@"UploadExtension Background Session became invalid! %@", error);
            
            // Session invalidated, Need to create new instance [KM]
            // Not so sure about this [AH]
            onceToken = onceTokenDefault;
        }];
    });
    
    return _sharedInstance;
}

#pragma mark - Overrides

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)
    {
        [self initialSetup];
    }
    
    return self;
}

- (void)initialSetup
{
    // TODO: eliminate dependency? [AH]
    self.requestSerializer = [VIMRequestSerializer serializerWithSession:[VIMSession sharedSession]];
    self.responseSerializer = [VIMResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
}

@end
