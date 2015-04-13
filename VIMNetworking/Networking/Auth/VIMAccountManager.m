//
//  ECAccountManager.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/29/13.
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

#import "VIMAccountManager.h"

#import <Accounts/ACAccountStore.h>

#import "VIMAccount.h"
#import "VIMAccountStore.h"
#import "VIMOAuthAuthenticator.h"
#import "VIMNetworking.h"
#import "VIMAccountCredential.h"
#import "VIMAPIClient+Private.h"

NSString * const kECAccountID_Vimeo = @"ECAccountID_Vimeo"; // TODO: eliminate this, no need [AH]

NSString * const kECAccountName_Vimeo = @"Vimeo"; // TODO: this too [AH]

NSString * const kVimeoAccessTokenPath = @"oauth/authorize/password";
NSString * const kVimeoClientCredentialsPath = @"oauth/authorize/client";
NSString * const kVimeoUsersPath = @"users";
NSString * const kVimeoFacebookTokenPath = @"oauth/authorize/facebook";
NSString * const kVimeoCodeGrantPath = @"oauth/access_token";

NSString * const VIMAccountManagerErrorDomain = @"VIMAccountManagerErrorDomain";

@interface VIMAccountManager ()
{
    BOOL _isInitialized;
    
    NSMutableArray *_accounts;
}

@end

@implementation VIMAccountManager

+ (VIMAccountManager *)sharedInstance
{
    static VIMAccountManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[VIMAccountManager alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _accounts = [NSMutableArray array];
        
        
        
        [self _initialize];
    }
    
    return self;
}

- (void)_initialize
{
    if(_isInitialized)
        return;
    
    VIMAccount *vimeoAccount = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    if(!vimeoAccount)
    {
        vimeoAccount = [[VIMAccount alloc] initWithAccountID:kECAccountID_Vimeo accountType:(NSString *)kVIMAccountType_Vimeo accountName:kECAccountName_Vimeo];
        [[VIMAccountStore sharedInstance] saveAccount:vimeoAccount];
    }
    
    [_accounts addObject:vimeoAccount];

    _isInitialized = YES;
}

#pragma mark - Public API

- (NSOperation *)authenticateWithClientCredentialsGrantAndCompletionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if([account isAuthenticated])
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }
 
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"grant_type" : kVIMOAuthGrantType_ClientCredentials}];

    NSString *scope = [VIMSession sharedSession].configuration.scope;
    NSString *credentialsGrantURL = [VIMAccountManager clientCredentialsURL];
    NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
    NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;

    if (scope)
    {
        [mutableParameters setValue:scope forKey:@"scope"];
    }

    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:credentialsGrantURL clientID:clientKey clientSecret:clientSecret];
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(error)
        {
            if(completionBlock)
                completionBlock(error);
        }
        else
        {
            if(completionBlock)
                completionBlock(nil);
        }
    }];
}

- (NSOperation *)authenticateWithCodeGrant:(NSString *)code completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock
{
    NSParameterAssert(code != nil);
    
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    NSString *tokenURLString = [VIMAccountManager codeGrantURL];
    NSString *redirectURI = [[VIMAPIClient sharedClient] codeGrantRedirectURI];
    VIMSessionConfiguration *sessionConfiguration = [VIMSession sharedSession].configuration;
    VIMOAuthAuthenticator *oAuthAuthenticator = [[VIMOAuthAuthenticator alloc] initWithURL:tokenURLString clientID:sessionConfiguration.clientKey clientSecret:sessionConfiguration.clientSecret];
    
    return [oAuthAuthenticator authenticateAccount:account code:code redirectURI:redirectURI completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(error)
        {
            NSLog(@"oauth code error: %@", error);
        }
        
        if (completionBlock)
        {
            completionBlock(error);
        }
    }];
}

- (NSOperation *)joinWithDisplayName:(NSString *)displayName email:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if([account isAuthenticated]) // TODO: Is this logic correct? [AH]
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }

    NSString *scope = [VIMSession sharedSession].configuration.scope;
    NSString *usersURL = [VIMAccountManager usersURL];
    NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
    NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;

    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setObject:displayName forKey:@"display_name"];
    [mutableParameters setValue:email forKey:@"email"];
    [mutableParameters setValue:password forKey:@"password"];
    [mutableParameters setValue:scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:usersURL clientID:clientKey clientSecret:clientSecret];
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(error)
        {
            if(completionBlock)
                completionBlock(error);
        }
        else
        {
            if(completionBlock)
                completionBlock(nil);
        }
    }];
}

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");

    if ([account isAuthenticated]) // TODO: Is this logic correct? [AH]
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    NSString *scope = [VIMSession sharedSession].configuration.scope;
    NSString *usersURL = [VIMAccountManager usersURL];
    NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
    NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;

    [mutableParameters setValue:facebookToken forKey:@"token"];
    [mutableParameters setValue:scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:usersURL clientID:clientKey clientSecret:clientSecret];
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(error)
        {
            if(completionBlock)
                completionBlock(error);
        }
        else
        {
            if(completionBlock)
                completionBlock(nil);
        }
    }];
}

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");

    if ([account isAuthenticated] && [account.credential isUserCredential]) // TODO: Is this logic correct? [AH]
    {
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(completionBlock)
            completionBlock(nil);
        
        return nil;
    }
    else
    {
        NSString *scope = [VIMSession sharedSession].configuration.scope;
        NSString *accessTokenURL = [VIMAccountManager accessTokenURL];
        NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
        NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;

        VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:accessTokenURL clientID:clientKey clientSecret:clientSecret];
        return [authenticator authenticateAccount:account email:email password:password scope:scope completionBlock:^(id responseObject, NSError *error) {
            
            [[VIMAccountStore sharedInstance] saveAccount:account];
            
            if(error)
            {
                if(completionBlock)
                    completionBlock(error);
            }
            else
            {
                if(completionBlock)
                    completionBlock(nil);
            }
        }];
    }
}

- (NSOperation *)loginWithFacebookToken:(NSString *)fbtoken completionBlock:(void (^)(BOOL, NSError *))completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");

    if ([account isAuthenticated] && [account.credential isUserCredential]) // TODO: Is this logic correct? [AH]
    {
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(completionBlock)
            completionBlock(YES, nil);
        
        return nil;
    }
    else
    {
        return [self makeFacebookAuthenticationRequestWithAccount:account facebookToken:fbtoken completionBlock:^(id responseObject, NSError *error) {
            
            [[VIMAccountStore sharedInstance] saveAccount:account];
            
            if(completionBlock)
                completionBlock(error == nil, error);
        }];
    }
}

- (void)logoutAccount:(VIMAccount *)account
{
    if (account)
    {
        [account deleteCredential];
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }    
}

- (void)refreshAccounts
{
    [[VIMAccountStore sharedInstance] reload];
}

#pragma mark - Private API

//- (void)temporaryAuthenticateVimeoAccountWithFacebookToken:(NSString *)fbtoken completionBlock:(void (^)(NSError *, BOOL, VIMAccount *))completionBlock
//{
//    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
//    VIMAccount *temporaryAccount = [[VIMAccount alloc] initWithAccountID:account.accountID accountType:account.accountType accountName:account.accountName];
//    [self makeFacebookAuthenticationRequestWithAccount:temporaryAccount facebookToken:fbtoken completionBlock:^(id responseObject, NSError *error)
//     {
//         if ( completionBlock )
//             completionBlock(error, error == nil, temporaryAccount);
//     }];
//}

- (NSOperation *)makeFacebookAuthenticationRequestWithAccount:(VIMAccount *)account facebookToken:(NSString *)fbtoken completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    NSAssert(account, @"No account found.");
    NSString *scope = [VIMSession sharedSession].configuration.scope;
    NSString *facebookURL = [VIMAccountManager facebookTokenURL];
    NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
    NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setObject:@"facebook" forKey:@"grant_type"];
    [mutableParameters setValue:fbtoken forKey:@"token"];
    [mutableParameters setValue:scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:facebookURL clientID:clientKey clientSecret:clientSecret];
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:completionBlock];
}

- (void)authenticateVimeoAccountWithJSONResponse:(id)JSON completionBlock:(void (^)(NSError *error))completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if([account isAuthenticated])
    {
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(completionBlock)
            completionBlock(nil);
    }
    else
    {
        NSString *accessTokenURL = [VIMAccountManager accessTokenURL];
        NSString *clientKey = [VIMSession sharedSession].configuration.clientKey;
        NSString *clientSecret = [VIMSession sharedSession].configuration.clientSecret;
        
        VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:accessTokenURL clientID:clientKey clientSecret:clientSecret];
        
        NSError *error = nil;
        
        if(![authenticator authenticateAccount:account withJSONResponse:JSON])
        {
            error = [NSError errorWithDomain:@"Error" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Unable to parse server response." forKey:NSLocalizedDescriptionKey]];
        }
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if(error)
        {
            if(completionBlock)
                completionBlock(error);
        }
        else
        {
            if(completionBlock)
                completionBlock(nil);
        }
    }
}

#pragma mark - Class Methods

+ (NSString *)clientCredentialsURL
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoClientCredentialsPath]  absoluteString];
}

+ (NSString *)codeGrantURL
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoCodeGrantPath]  absoluteString];
}

+ (NSString *)accessTokenURL
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoAccessTokenPath]  absoluteString];
}

+ (NSString *)usersURL
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoUsersPath]  absoluteString];
}

+ (NSString *)facebookTokenURL
{
    NSURL *baseURL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoFacebookTokenPath]  absoluteString];
}

@end
