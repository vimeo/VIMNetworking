//
//  VIMSession.m
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/19/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
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

#import "VIMSession.h"
#import "VIMAccountStore.h"
#import "VIMRequestOperationManager.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"
#import "VIMAuthenticator+Private.h"
#import "VIMReachability.h"
#import "VIMCache.h"
#import "VIMObjectMapper.h"

static NSString *const ClientCredentialsAccountKey = @"ClientCredentialsAccountKey";
static NSString *const UserAccountKey = @"UserAccountKey";

NSString *const VIMSession_AuthenticatedAccountDidChangeNotification = @"VIMSession_AuthenticatedAccountDidChangeNotification";
NSString *const VIMSession_AuthenticatedUserDidRefreshNotification = @"VIMSession_AuthenticatedUserDidRefreshNotification";

@interface VIMSession () <VIMRequestOperationManagerDelegate>

@property (nonatomic, strong, readwrite) VIMAccountNew *account;
@property (nonatomic, strong, readwrite) VIMAuthenticator *authenticator;
@property (nonatomic, strong, readwrite) VIMClient *client;

@property (nonatomic, weak) id<VIMRequestToken> currentUserRefreshRequest;

@end

@implementation VIMSession

static VIMSession *_sharedSession;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
        _authenticator = [self buildAuthenticator];
        _client = [self buildClient];
        
        [VIMReachability sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    
    return self;
}

#pragma mark - Notifications

- (void)applicationDidEnterForeground:(NSNotification *)notification
{
    self.account = [self loadAccountIfPossible]; // Reload account in the event that an auth event occurred in the an app extension
    self.client.cache = [self buildCache];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });

    if (self.currentUserRefreshRequest)
    {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.currentUserRefreshRequest = [self refreshAuthenticatedUserWithCompletionBlock:^(NSError *error) {
        
        weakSelf.currentUserRefreshRequest = nil;
        
    }];
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

- (NSString *)acceptHeaderValue:(VIMRequestOperationManager *)operationManager
{
    VIMRequestSerializer *requestSerializer = [[VIMRequestSerializer alloc] initWithAPIVersionString:self.configuration.APIVersionString];

    return [requestSerializer acceptHeaderValue];
}

#pragma mark - Private API

- (VIMAccountNew *)loadAccountIfPossible
{
    VIMAccountNew *account = [VIMAccountStore loadAccountForKey:UserAccountKey];
    
    if (account == nil)
    {
        account = [VIMAccountStore loadAccountForKey:ClientCredentialsAccountKey];
    }
    
    // Migrate legacy account
    if (account == nil)
    {
        account = [VIMAccountStore loadLegacyAccount];
        if (account)
        {
            NSString *key = [account isAuthenticatedWithUser] ? UserAccountKey : ClientCredentialsAccountKey;
            
            BOOL success = [VIMAccountStore saveAccount:account forKey:key];
            
            NSAssert(success, @"Unable to save account for key: %@", key);
            
            if (!success)
            {
                NSLog(@"Unable to save account for key: %@", key);
            }
        }
    }

    return account;
}

- (VIMAuthenticator *)buildAuthenticator
{
    NSURL *baseURL = [NSURL URLWithString:self.configuration.baseURLString];
    
    VIMAuthenticator *authenticator = [[VIMAuthenticator alloc] initWithBaseURL:baseURL
                                                                      clientKey:self.configuration.clientKey
                                                                   clientSecret:self.configuration.clientSecret
                                                                          scope:self.configuration.scope];
    authenticator.requestSerializer = [AFHTTPRequestSerializer serializer];
    authenticator.responseSerializer = [AFJSONResponseSerializer serializer];
    authenticator.delegate = self;
    
    return authenticator;
}

- (VIMClient *)buildClient
{
    NSURL *baseURL = [NSURL URLWithString:self.configuration.baseURLString];

    VIMClient *client = [[VIMClient alloc] initWithBaseURL:baseURL];
    client.requestSerializer = [[VIMRequestSerializer alloc] initWithAPIVersionString:self.configuration.APIVersionString];
    client.delegate = self;
    client.cache = [self buildCache];
   
    return client;
}

- (VIMCache *)buildCache
{
    VIMCache *cache = [VIMCache sharedCache];
    
    if (self.account && [self.account isAuthenticatedWithUser])
    {
        NSString *name = [NSString stringWithFormat:@"user_%@", [self.account.user objectID]];
        cache = [[VIMCache alloc] initWithName:name];
    }
    
    return cache;
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

- (void)authenticationCompleteWithAccount:(VIMAccountNew *)account error:(NSError *)error key:(NSString *)key completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSParameterAssert(key);
    NSAssert((account || error) && !(account && error), @"account and error are mutually exclusive");
    NSParameterAssert(completionBlock);
    
    if (error)
    {
        if (completionBlock)
        {
            completionBlock(error);
        }
        
        return;
    }
    
    if (!key)
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"VIMAccountStore key cannot be nil"}];
            completionBlock(error);
        }

        return;
    }
    
    BOOL success = [VIMAccountStore saveAccount:account forKey:key];
    
    NSAssert(success, @"Unable to save account for key: %@", key);
    
    if (!success)
    {
        NSLog(@"Unable to save account for key: %@", key);
    }

    self.account = account;
    self.client.cache = [self buildCache];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });
    
    if (completionBlock)
    {
        completionBlock(nil);
    }
}

#pragma mark - Public API

#pragma mark Authentication

- (id<VIMRequestToken>)authenticateWithClientCredentialsGrant:(VIMErrorCompletionBlock)completionBlock
{
    if ([self.account isAuthenticatedWithClientCredentials] && !self.account.isInvalid)
    {
        if (completionBlock)
        {
            completionBlock(nil);
        }
        
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    return [self.authenticator authenticateWithClientCredentialsGrant:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:ClientCredentialsAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    __weak typeof(self) weakSelf = self;
    return [self.authenticator authenticateWithCodeGrantResponseURL:responseURL completionBlock:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    __weak typeof(self) weakSelf = self;
    return [self.authenticator loginWithEmail:email password:password completionBlock:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)joinWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    __weak typeof(self) weakSelf = self;
    return [self.authenticator joinWithName:name email:email password:password completionBlock:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    __weak typeof(self) weakSelf = self;
    return [self.authenticator loginWithFacebookToken:facebookToken completionBlock:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    __weak typeof(self) weakSelf = self;
    return [self.authenticator joinWithFacebookToken:facebookToken completionBlock:^(VIMAccountNew *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)logout
{
    NSAssert([self.account isAuthenticatedWithUser], @"logout can only occur when a user is logged in");
    if (![self.account isAuthenticatedWithUser] && !self.account.isInvalid)
    {
        return nil;
    }

    // Must call logout before account is changed [AH]
    id<VIMRequestToken> logoutRequest = [self.client logoutWithCompletionBlock:nil];

    VIMAccountNew *account = [VIMAccountStore loadAccountForKey:ClientCredentialsAccountKey];
    
    BOOL success = [VIMAccountStore deleteAccountForKey:UserAccountKey];
    if (!success)
    {
        NSLog(@"Unable to delete account for key: %@", UserAccountKey);
    }
    
    self.account = account;
    
    [self.client.cache removeAllObjects];
    self.client.cache = [self buildCache];

    // Client Credentials Account can be nil if upgraded from v5.4.2 as a logged in user. [AH]
    if (account == nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kVimeoClient_InvalidTokenNotification object:nil];
        });
        
        return nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });

    return logoutRequest;
}

#pragma mark Configuration

- (BOOL)changeAccount:(VIMAccountNew *)account
{
    NSParameterAssert(account);
    if (account == nil || ![account isAuthenticated] || ([account isAuthenticatedWithUser] && (account.user == nil || account.userJSON == nil)))
    {
        return NO;
    }
    
    BOOL success = NO;
    
    if ([account isAuthenticatedWithClientCredentials])
    {
        success = [VIMAccountStore saveAccount:account forKey:ClientCredentialsAccountKey];
    }
    else
    {
        success = [VIMAccountStore saveAccount:account forKey:UserAccountKey];
    }
    
    NSAssert(success, @"Unable to save account");
    if (!success)
    {
        NSLog(@"Unable to save account");
    }
    
    self.account = account;
    self.client.cache = [self buildCache];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });
    
    return YES;
}

- (BOOL)changeBaseURL:(NSString *)baseURLString
{
    NSParameterAssert(baseURLString);
    
    if (baseURLString == nil || [self.configuration.baseURLString isEqualToString:baseURLString])
    {
        return NO;
    }
    
    self.configuration.baseURLString = baseURLString;

    self.authenticator = [self buildAuthenticator];
    self.client = [self buildClient];
    
    return YES;
}

- (id<VIMRequestToken>)refreshAuthenticatedUserWithCompletionBlock:(VIMErrorCompletionBlock)completionBlock
{
    if (self.account == nil || ![self.account isAuthenticatedWithUser])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to refresh user, no account or account is not authenticated."}];
            completionBlock(error);
        }
        
        return nil;
    }
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.cachePolicy = VIMCachePolicy_NetworkOnly;
    descriptor.urlPath = @"/me";
    
    __weak typeof(self) weakSelf = self;
    return [self.client requestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (error)
        {
            if (completionBlock)
            {
                completionBlock(error);
            }
            
            return;
        }
        
        if (response == nil || response.result == nil)
        {
            if (completionBlock)
            {
                NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Unable to refresh user, no account or account is not authenticated."}];
                completionBlock(error);
            }
            
            return;
        }
        
        VIMObjectMapper *mapper = [[VIMObjectMapper alloc] init];
        [mapper addMappingClass:[VIMUser class] forKeypath:@""];
        VIMUser *user = [mapper applyMappingToJSON:response.result];

        strongSelf.account.user = user;
        strongSelf.account.userJSON = response.result;
        
        BOOL success = [VIMAccountStore saveAccount:strongSelf.account forKey:UserAccountKey];
        NSAssert(success, @"Unable to save account for key: %@", UserAccountKey);
        
        if (!success)
        {
            NSLog(@"Unable to save account for key: %@", UserAccountKey);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedUserDidRefreshNotification object:nil];
        });

        if (completionBlock)
        {
            completionBlock(nil);
        }
        
    }];
}

@end
