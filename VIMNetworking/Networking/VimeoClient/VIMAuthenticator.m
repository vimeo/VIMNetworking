//
//  VIMAuthenticator.m
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/21/15.
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

// Legacy apple account id: com.apple.social.vimeo [AH]

#import "VIMAuthenticator.h"
#import "VIMAccount.h"

NSString * const kVimeoAuthenticatorErrorDomain = @"kVimeoAuthenticatorErrorDomain";

NSString * const kVimeoAccessTokenPath = @"oauth/authorize/password";
NSString * const kVimeoClientCredentialsPath = @"oauth/authorize/client";
NSString * const kVimeoUsersPath = @"users";
NSString * const kVimeoFacebookTokenPath = @"oauth/authorize/facebook";
NSString * const kVimeoCodeGrantPath = @"oauth/access_token";

NSString * const kVIMOAuthGrantType_AuthorizationCode = @"authorization_code";
NSString * const kVIMOAuthGrantType_ClientCredentials = @"client_credentials";
NSString * const kVIMOAuthGrantType_Password = @"password";
NSString * const kVIMOAuthGrantType_Facebook = @"facebook";

@interface VIMAuthenticator ()

@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong, readwrite) NSString *clientKey;
@property (nonatomic, strong, readwrite) NSString *clientSecret;
@property (nonatomic, strong, readwrite) NSString *scope;

@end

@implementation VIMAuthenticator

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                      clientKey:(NSString *)clientKey
                   clientSecret:(NSString *)clientSecret
                          scope:(NSString *)scope
{
    NSParameterAssert(baseURL && clientKey && clientSecret && scope);
    
    if (![[baseURL absoluteString] length] || ![clientKey length] || ![clientSecret length] || ![scope length])
    {
        return nil;
    }
    
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

- (id<VIMRequestToken>)authenticateWithClientCredentialsGrant:(VIMAccountCompletionBlock)completionBlock
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:kVIMOAuthGrantType_ClientCredentials forKey:@"grant_type"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    return [self authenticateWithPath:kVimeoClientCredentialsPath parameters:mutableParameters completionBlock:completionBlock];
}

- (id<VIMRequestToken>)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(responseURL);
    
    NSString *parameterString = responseURL.query;
    NSDictionary *responseParameters = VIMParametersFromQueryString(parameterString);
    
    NSString *code = responseParameters[@"code"];
    NSString *state = responseParameters[@"state"];
    
    if (!code || !state || ![state isEqualToString:self.state])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Invalid code or state"}];
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:kVIMOAuthGrantType_AuthorizationCode forKey:@"grant_type"];
    [mutableParameters setValue:code forKey:@"code"];
    [mutableParameters setValue:[self codeGrantRedirectURI] forKey:@"redirect_uri"];
    
    return [self authenticateWithPath:kVimeoCodeGrantPath parameters:mutableParameters completionBlock:completionBlock];
}

#pragma mark - Private API (Category Methods)

- (id<VIMRequestToken>)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(email);
    NSParameterAssert(password);
    
    if (![email length] || ![password length])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"email and password cannot be nil"}];
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setObject:kVIMOAuthGrantType_Password forKey:@"grant_type"];
    [mutableParameters setValue:email forKey:@"username"];
    [mutableParameters setValue:password forKey:@"password"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    return [self authenticateWithPath:kVimeoAccessTokenPath parameters:mutableParameters completionBlock:completionBlock];
}

- (id<VIMRequestToken>)joinWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(name);
    NSParameterAssert(email);
    NSParameterAssert(password);
    
    if (![name length] || ![email length] || ![password length])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"name, email and password cannot be nil"}];
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:name forKey:@"display_name"];
    [mutableParameters setValue:email forKey:@"email"];
    [mutableParameters setValue:password forKey:@"password"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    return [self authenticateWithPath:kVimeoUsersPath parameters:mutableParameters completionBlock:completionBlock];
}

- (id<VIMRequestToken>)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(facebookToken);
    
    if (![facebookToken length])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"facebook token cannot be nil"}];
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:kVIMOAuthGrantType_Facebook forKey:@"grant_type"];
    [mutableParameters setValue:facebookToken forKey:@"token"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    return [self authenticateWithPath:kVimeoFacebookTokenPath parameters:mutableParameters completionBlock:completionBlock];
}

- (id<VIMRequestToken>)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(facebookToken);
    
    if (![facebookToken length])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"facebook token cannot be nil"}];
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:facebookToken forKey:@"token"];
    [mutableParameters setValue:self.scope forKey:@"scope"];
    
    return [self authenticateWithPath:kVimeoUsersPath parameters:mutableParameters completionBlock:completionBlock];
}

#pragma mark - Private API

- (id<VIMRequestToken>)authenticateWithPath:(NSString *)path parameters:(NSMutableDictionary *)parameters completionBlock:(VIMAccountCompletionBlock)completionBlock
{
    NSParameterAssert(path);
    NSParameterAssert(parameters);
    NSParameterAssert(completionBlock);
    
    [parameters setObject:self.clientKey forKey:@"client_id"];
//    [parameters setObject:self.clientSecret forKey:@"client_secret"];

    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = path;
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.modelClass = [VIMAccount class];
    descriptor.parameters = parameters;
    
    __weak typeof(self) weakSelf = self;
    return [self requestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (completionBlock == nil)
        {
            return;
        }
        
        if (error)
        {
            completionBlock(nil, error);
            
            return;
        }
        
        VIMAccount *account = response.result;
        
        if (account == nil)
        {
            NSError *error = [NSError errorWithDomain:kVimeoAuthenticatorErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"account returned is nil"}];
            completionBlock(nil, error);
            
            return;
        }
        
        completionBlock(account, nil);
        
    }];
}

@end
