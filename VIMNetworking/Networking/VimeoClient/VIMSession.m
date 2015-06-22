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

static NSString *const ClientCredentialsAccountKey = @"ClientCredentialsAccountKey";
static NSString *const UserAccountKey = @"UserAccountKey";

NSString *const VIMSession_AuthenticatedAccountDidChangeNotification = @"VIMSession_AuthenticatedAccountDidChangeNotification";
NSString *const VIMSession_AuthenticatedUserDidRefreshNotification = @"VIMSession_AuthenticatedUserDidRefreshNotification";

@interface VIMSession () <VIMRequestOperationManagerDelegate>

@property (nonatomic, strong, readwrite) VIMAccount *account;
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

    typeof(self) weakSelf = self;
    self.currentUserRefreshRequest = [self refreshAuthenticatedUserWithCompletionBlock:^(NSError *error) {
        
        weakSelf.currentUserRefreshRequest = nil;
        
        // TODO: check for invalid token error [AH]
        
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

#pragma mark - Private API

- (VIMAccount *)loadAccountIfPossible
{
    VIMAccount *account = [VIMAccountStore loadAccountForKey:UserAccountKey];
    
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
            [VIMAccountStore saveAccount:account forKey:key];
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
    authenticator.requestSerializer = [[VIMRequestSerializer alloc] initWithAPIVersionString:self.configuration.APIVersionString];
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
    
    if ([self.account isAuthenticatedWithUser])
    {
        NSString *name = [NSString stringWithFormat:@"user_%@", self.account.user.objectID];
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

- (void)authenticationCompleteWithAccount:(VIMAccount *)account error:(NSError *)error key:(NSString *)key completionBlock:(VIMErrorCompletionBlock)completionBlock
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
    
    [VIMAccountStore saveAccount:account forKey:key];

    self.account = account;
    self.client.cache = [self buildCache];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });
}

#pragma mark - Public API

#pragma mark Authentication

- (id<VIMRequestToken>)authenticateWithClientCredentialsGrant:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithClientCredentials] == NO, @"Attempt to authenticate with client credentials grant when already authenticated with client credentials grant");
    
    if ([self.account isAuthenticatedWithClientCredentials])
    {
        if (completionBlock)
        {
            completionBlock(nil);
        }
        
        return nil;
    }
    
    typeof(self) weakSelf = self;
    return [self.authenticator authenticateWithClientCredentialsGrant:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:ClientCredentialsAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    typeof(self) weakSelf = self;
    return [self.authenticator authenticateWithCodeGrantResponseURL:responseURL completionBlock:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    typeof(self) weakSelf = self;
    return [self.authenticator loginWithEmail:email password:password completionBlock:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)joinWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    typeof(self) weakSelf = self;
    return [self.authenticator joinWithName:name email:email password:password completionBlock:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    typeof(self) weakSelf = self;
    return [self.authenticator loginWithFacebookToken:facebookToken completionBlock:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser] == NO, @"Attempt to authenticate as user when already authenticated as user");

    typeof(self) weakSelf = self;
    return [self.authenticator joinWithFacebookToken:facebookToken completionBlock:^(VIMAccount *account, NSError *error) {
        
        [weakSelf authenticationCompleteWithAccount:account error:error key:UserAccountKey completionBlock:completionBlock];

    }];
}

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSAssert([self.account isAuthenticatedWithUser], @"logout can only occur when a user is logged in");
    if (![self.account isAuthenticatedWithUser])
    {
        return nil;
    }

    VIMAccount *account = [VIMAccountStore loadAccountForKey:ClientCredentialsAccountKey];
    [VIMAccountStore deleteAccount:self.account forKey:UserAccountKey];
    self.account = account;
    
    NSAssert(self.account != nil, @"account cannot be nil after logging out");
    
    [self.client.cache removeAllObjects];
    self.client.cache = [self buildCache];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedAccountDidChangeNotification object:nil];
    });

    return [self.client logoutWithCompletionBlock:completionBlock];
}

#pragma mark Configuration

- (void)changeBaseURL:(NSString *)baseURLString
{
    NSParameterAssert(baseURLString);
    
    if (baseURLString == nil)
    {
        return;
    }
    
    self.configuration.baseURLString = baseURLString;

    self.authenticator = [self buildAuthenticator];
    self.client = [self buildClient];
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
    descriptor.modelClass = [VIMUser class];
    
    typeof(self) weakSelf = self;
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
        
        VIMUser *user = response.result;
        strongSelf.account.user = user;
        
        [VIMAccountStore saveAccount:strongSelf.account forKey:UserAccountKey];
        
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
