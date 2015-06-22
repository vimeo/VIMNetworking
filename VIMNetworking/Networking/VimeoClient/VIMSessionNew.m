//
//  VIMSessionNew.m
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/19/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMSessionNew.h"
#import "VIMSessionConfiguration.h"
#import "VIMAuthenticator.h"
#import "VIMClient.h"
#import "VIMAccount.h"
#import "VIMAccountStore.h"
#import "VIMRequestOperationManager.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"

static NSString *const ClientCredentialsAccountKey = @"ClientCredentialsAccountKey";
static NSString *const UserAccountKey = @"UserAccountKey";

static NSString *const AuthenticatedUserDataDidUpdateNotification = @"AuthenticatedUserDataDidUpdateNotification"; // TODO: refresh user and post this [AH]

@interface VIMSessionNew () <VIMRequestOperationManagerDelegate>

@end

@implementation VIMSessionNew

static VIMSessionNew *_sharedSession;

+ (instancetype)sharedSession
{
    return _sharedSession;
}

+ (void)setupWithConfiguration:(VIMSessionConfiguration *)configuration
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedSession = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype)initWithConfiguration:(VIMSessionConfiguration *)configuration
{    
    NSAssert([configuration isValid], @"Attempt to initialize session with an invalid configuration");
    
    self = [super init];
    if (self)
    {
        _configuration = configuration;
        
        _account = [self loadAccountIfPossible];
        
        NSURL *baseURL = [NSURL URLWithString:self.configuration.baseURLString];
        
        _authenticator = [[VIMAuthenticator alloc] initWithBaseURL:baseURL
                                                         clientKey:self.configuration.clientKey
                                                      clientSecret:self.configuration.clientSecret
                                                             scope:self.configuration.scope];
        _authenticator.requestSerializer = [[VIMRequestSerializer alloc] initWithAPIVersionString:self.configuration.APIVersionString];
        _authenticator.delegate = self;
        
        _client = [[VIMClient alloc] initWithBaseURL:baseURL];
        _client.requestSerializer = [[VIMRequestSerializer alloc] initWithAPIVersionString:self.configuration.APIVersionString];
        _client.delegate = self;
        _client.cache = nil; // TODO: set this to non-nil value [AH]
    }
    
    return self;
}

#pragma mark - VIMRequestOperationManager Delegate

- (NSString *)authorizationHeaderValue:(VIMRequestOperationManager *)operationManager
{
    if (operationManager == self.authenticator)
    {
        return [self basicAuthorizationHeaderValue];
    }
    
    NSString *value = [self bearerAuthorizationHeaderValue];
    if (value == nil)
    {
        value = [self basicAuthorizationHeaderValue];
    }
    
    return value;
}

#pragma mark - Private API

- (VIMAccount *)loadAccountIfPossible
{
    VIMAccount *account = [VIMAccountStore loadAccountForKey:UserAccountKey];
    
    if (account == nil)
    {
        account = [VIMAccountStore loadAccountForKey:ClientCredentialsAccountKey];
    }
    
    return account;
}

- (NSString *)basicAuthorizationHeaderValue
{
    NSString *authString = [NSString stringWithFormat:@"%@:%@", self.configuration.clientKey, self.configuration.clientSecret];
    NSData *plainData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    
    return [NSString stringWithFormat:@"Basic %@", base64String];
}

- (NSString *)bearerAuthorizationHeaderValue
{
    if (self.account.accessToken && [[self.account.tokenType lowercaseString] isEqualToString:@"bearer"])
    {
        return [NSString stringWithFormat:@"Bearer %@", self.account.accessToken];
    }

    return nil;
}

#pragma mark - Public API

@end
