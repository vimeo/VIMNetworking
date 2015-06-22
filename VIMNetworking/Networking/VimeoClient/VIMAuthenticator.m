//
//  VIMAuthenticator.m
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/21/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

// Legacy apple account id: com.apple.social.vimeo [AH]

#import "VIMAuthenticator.h"

NSString * const kVimeoAccessTokenPath = @"oauth/authorize/password";
NSString * const kVimeoClientCredentialsPath = @"oauth/authorize/client";
NSString * const kVimeoUsersPath = @"users";
NSString * const kVimeoFacebookTokenPath = @"oauth/authorize/facebook";
NSString * const kVimeoCodeGrantPath = @"oauth/access_token";

@interface VIMAuthenticator ()

@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *clientKey;
@property (nonatomic, strong) NSString *clientSecret;
@property (nonatomic, strong) NSString *scope;

@end

@implementation VIMAuthenticator

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                      clientKey:(NSString *)clientKey
                   clientSecret:(NSString *)clientSecret
                          scope:(NSString *)scope
{
    NSParameterAssert(baseURL && clientKey && clientSecret && scope);
    
    self = [super initWithBaseURL:baseURL];
    if (self)
    {
        _state = [NSProcessInfo processInfo].globallyUniqueString;
        _clientKey = clientKey;
        _clientSecret = clientSecret;
        _scope = scope;
    }
    
    return self;
}

#pragma mark - URLs

- (NSURL *)codeGrantAuthorizationURL
{
    
    NSString *redirectURI = [self codeGrantRedirectURI];
    
    NSDictionary *parameters = @{@"response_type" : @"code",
                                 @"client_id" : self.clientKey,
                                 @"redirect_uri" : redirectURI,
                                 @"scope" : self.scope,
                                 @"state" : self.state};
    
    NSString *authenticationURLString = [self.baseURL.absoluteString stringByAppendingString:@"oauth/authorize"];
    
    NSError *error = nil;
    
    NSMutableURLRequest *urlRequest = [self.requestSerializer requestWithMethod:@"GET" URLString:authenticationURLString parameters:parameters error:&error];
    
    if (error)
    {
        return nil;
    }
    
    return urlRequest.URL;
}

- (NSString *)codeGrantRedirectURI
{
    NSString *authRedirectScheme = [NSString stringWithFormat:@"vimeo%@", self.clientKey];
    NSString *authRedirectPath = @"auth";
    
    return [NSString stringWithFormat:@"%@://%@", authRedirectScheme, authRedirectPath];
}

#pragma mark - Authentication

- (NSOperation *)authenticateWithClientCredentialsGrant:(VIMAuthenticatorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if([account isAuthenticated])
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"grant_type" : kVIMOAuthGrantType_ClientCredentials}];
    
    NSString *credentialsGrantURL = [VIMAuthenticator clientCredentialsURL];
    
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:credentialsGrantURL clientID:self.clientKey clientSecret:self.clientSecret];
    
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

- (NSOperation *)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock
{
    NSString *parameterString = responseURL.query;
    NSDictionary *responseParameters = VIMParametersFromQueryString(parameterString);
    NSString *code = responseParameters[@"code"];
    NSString *state = responseParameters[@"state"];
    
    if ( !code || !state || ![state isEqualToString:self.state] )
    {
        NSError *error = [NSError errorWithDomain:@"Error" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Invalid parameters for code grant response url"}];
        
        if (completionBlock)
        {
            completionBlock(error);
        }
        
        return nil;
    }
    
    NSParameterAssert(code != nil);
    
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    NSString *tokenURLString = [VIMAuthenticator codeGrantURL];
    NSString *redirectURI = [self codeGrantRedirectURI];
    VIMOAuthAuthenticator *oAuthAuthenticator = [[VIMOAuthAuthenticator alloc] initWithURL:tokenURLString clientID:self.clientKey clientSecret:self.clientSecret];
    
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

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if ([account isAuthenticated] && [account.credential isUserCredential]) // TODO: Is this logic correct? [AH]
    {
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if (completionBlock)
        {
            completionBlock(nil);
        }
        
        return nil;
    }
    
    NSString *accessTokenURL = [VIMAuthenticator accessTokenURL];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:accessTokenURL clientID:self.clientKey clientSecret:self.clientSecret];
   
    return [authenticator authenticateAccount:account email:email password:password scope:self.scope completionBlock:^(id responseObject, NSError *error) {
        
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

- (NSOperation *)joinWithDisplayName:(NSString *)displayName email:(NSString *)email password:(NSString *)password completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if ([account isAuthenticated]) // TODO: Is this logic correct? [AH]
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }
    
    NSString *usersURL = [VIMAuthenticator usersURL];
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setObject:displayName forKey:@"display_name"];
    [mutableParameters setValue:email forKey:@"email"];
    [mutableParameters setValue:password forKey:@"password"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:usersURL clientID:self.clientKey clientSecret:self.clientSecret];
    
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if (completionBlock)
        {
            completionBlock(error);
        }
        
    }];
}

- (NSOperation *)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if ([account isAuthenticated] && [account.credential isUserCredential]) // TODO: Is this logic correct? [AH]
    {
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if (completionBlock)
        {
            completionBlock(YES, nil);
        }
        
        return nil;
    }
    
    return [self makeFacebookAuthenticationRequestWithAccount:account facebookToken:fbtoken completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if (completionBlock)
        {
            completionBlock(error == nil, error);
        }
        
    }];
}

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock
{
    VIMAccount *account = [[VIMAccountStore sharedInstance] accountWithID:kECAccountID_Vimeo];
    NSAssert(account, @"No account found.");
    
    if ([account isAuthenticated]) // TODO: Is this logic correct? [AH]
    {
        [account deleteCredential];
        [[VIMAccountStore sharedInstance] saveAccount:account];
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    NSString *usersURL = [VIMAuthenticator usersURL];
    
    [mutableParameters setValue:facebookToken forKey:@"token"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    VIMOAuthAuthenticator *authenticator = [[VIMOAuthAuthenticator alloc] initWithURL:usersURL clientID:self.clientKey clientSecret:self.clientSecret];
    
    return [authenticator authenticateAccount:account parameters:mutableParameters completionBlock:^(id responseObject, NSError *error) {
        
        [[VIMAccountStore sharedInstance] saveAccount:account];
        
        if (completionBlock)
        {
            completionBlock(error);
        }
        
    }];
}

#pragma mark - Private API

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

#pragma mark - URLs

+ (NSString *)clientCredentialsURL
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoClientCredentialsPath]  absoluteString];
}

+ (NSString *)codeGrantURL
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoCodeGrantPath]  absoluteString];
}

+ (NSString *)accessTokenURL
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoAccessTokenPath]  absoluteString];
}

+ (NSString *)usersURL
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoUsersPath]  absoluteString];
}

+ (NSString *)facebookTokenURL
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [[baseURL URLByAppendingPathComponent:kVimeoFacebookTokenPath]  absoluteString];
}

@end
