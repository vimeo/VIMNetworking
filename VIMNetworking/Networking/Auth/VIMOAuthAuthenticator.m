//
//  VIMOAuthAuthenticator.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/30/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMOAuthAuthenticator.h"
#import "AFHTTPRequestOperationManager.h"
#import "VIMAccount.h"
#import "VIMAccountCredential.h"
#import "VIMRequestSerializer.h"
#import "VIMSession.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

static NSString * const SLServiceTypeVimeo = @"com.apple.social.vimeo";

NSString * const kVIMOAuthGrantType_AuthorizationCode = @"authorization_code";
NSString * const kVIMOAuthGrantType_ClientCredentials = @"client_credentials";
NSString * const kVIMOAuthGrantType_Password = @"password";
NSString * const kVIMOAuthGrantType_RefreshToken = @"refresh_token";

@interface VIMOAuthAuthenticator ()

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;

@end

@implementation VIMOAuthAuthenticator

- (instancetype)initWithURL:(NSString *)url clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret
{
    self = [super init];
    if (self)
    {
        _url = url;
        _clientID = clientID;
        _clientSecret = clientSecret;
    }
    
    return self;
}

- (NSOperation *)authenticateAccount:(VIMAccount *)account email:(NSString *)email password:(NSString *)password scope:(NSString *)scope completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    account.username = email;
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setObject:kVIMOAuthGrantType_Password forKey:@"grant_type"];
    [mutableParameters setValue:email forKey:@"username"];
    [mutableParameters setValue:password forKey:@"password"];
    [mutableParameters setValue:scope forKey:@"scope"];
    
    return [self authenticateAccount:account parameters:mutableParameters completionBlock:completionBlock];
}

- (NSOperation *)authenticateAccount:(VIMAccount *)account code:(NSString *)code redirectURI:(NSString *)redirectURI completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setObject:kVIMOAuthGrantType_AuthorizationCode forKey:@"grant_type"];
    [mutableParameters setValue:code forKey:@"code"];
    [mutableParameters setValue:redirectURI forKey:@"redirect_uri"];
    
    return [self authenticateAccount:account parameters:mutableParameters completionBlock:completionBlock];
}

- (NSOperation *)authenticateAccount:(VIMAccount *)account parameters:(NSDictionary *)params completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    
    // For Vimeo account, only send client ID for unauthenticated requests
    
    [parameters setObject:self.clientID forKey:@"client_id"];
    
    if(![account.accountType isEqualToString:(NSString *)kVIMAccountType_Vimeo])
        [parameters setObject:self.clientSecret forKey:@"client_secret"];
    
    
    AFHTTPRequestOperationManager *client = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:self.url]];
    client.responseSerializer = [AFJSONResponseSerializer serializer];
    
    VIMRequestSerializer *requestSerializater = [VIMRequestSerializer serializerWithSession:[VIMSession sharedSession]];

    if([account.accountType isEqualToString:(NSString *)kVIMAccountType_Vimeo])
    {
        [client.requestSerializer setValue:[requestSerializater JSONAcceptHeaderString] forHTTPHeaderField:@"Accept"];
        // Set basic auth header
        NSString *tokenString = [NSString stringWithFormat:@"%@:%@", self.clientID, self.clientSecret];
        
        NSData *plainData = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64String = [plainData base64EncodedStringWithOptions:0];

        NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [base64String stringByReplacingOccurrencesOfString:@"\r\n" withString:@""]];
        [client.requestSerializer setValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        [client.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    
    NSURL *url = client.baseURL;
    
    NSURLRequest *request = nil;
    
    if(self.ac_account == nil)
    {
        request = [client.requestSerializer requestWithMethod:@"POST" URLString:[url absoluteString] parameters:parameters error:nil];
    }
    else
    {
        [parameters setObject:self.clientSecret forKey:@"client_secret"];
        
        SLRequest *sl_request = [SLRequest requestForServiceType:SLServiceTypeVimeo requestMethod:SLRequestMethodPOST
                                                             URL:url parameters:parameters];
        
        sl_request.account = self.ac_account;
        
        request = [sl_request preparedURLRequest];
        
        NSDictionary *headers = request.allHTTPHeaderFields;
        
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:request.URL];
        [mutableRequest setHTTPMethod:request.HTTPMethod];
        [mutableRequest setValue:[requestSerializater JSONAcceptHeaderString] forHTTPHeaderField:@"Accept"];
        [mutableRequest setValue:headers[@"Authorization"] forHTTPHeaderField:@"Authorization"];
        [mutableRequest setHTTPBody:request.HTTPBody];
        
        request = mutableRequest;
    }
    
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *JSON = responseObject;
         
        //NSLog(@"JSON: %@", JSON);
        
        NSError *error = nil;
        if (![self authenticateAccount:account withJSONResponse:JSON andParameters:parameters])
        {
            error = [NSError errorWithDomain:@"Error" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Unable to parse server response." forKey:NSLocalizedDescriptionKey]];
        }
        
        if (error)
        {
            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            
            return;
        }

        if (completionBlock)
        {
            completionBlock(JSON, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (completionBlock)
        {
            completionBlock(nil, error);
        }

    }];

    [client.operationQueue addOperation:operation];
    
    return operation;
}

#pragma mark - 

- (BOOL)authenticateAccount:(VIMAccount *)account withJSONResponse:(id)JSON
{
    return [self authenticateAccount:account withJSONResponse:JSON andParameters:nil];
}

- (BOOL)authenticateAccount:(VIMAccount *)account withJSONResponse:(id)JSON andParameters:(NSDictionary *)parameters
{
    if(JSON == nil)
        return NO;
    
    NSString *accessToken = [JSON valueForKey:@"access_token"];
    if(accessToken == nil || [accessToken isEqual:[NSNull null]] || [accessToken length] == 0)
        return NO;

    VIMAccountCredential *credential = [[VIMAccountCredential alloc] init];
    
    credential.accessToken = accessToken;
    credential.tokenType = [JSON valueForKey:@"token_type"];
    
    NSString *refreshToken = [JSON valueForKey:@"refresh_token"];
    if(refreshToken == nil || [refreshToken isEqual:[NSNull null]])
    {
        if(parameters)
            refreshToken = [parameters valueForKey:@"refresh_token"];
    }

    if(parameters)
    {
        NSString *grantType = [parameters valueForKey:@"grant_type"];
        if (grantType)
        {
            credential.grantType = grantType;
        }
    }
    
    NSDate *expirationDate = nil;
    id expiresIn = [JSON valueForKey:@"expires_in"];
    if (expiresIn != nil && ![expiresIn isEqual:[NSNull null]])
        expirationDate = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
    
    credential.refreshToken = refreshToken;
    credential.expirationDate = expirationDate;
    
    account.credential = credential;
    
    account.serverResponse = JSON;
    
    account.username = [[JSON valueForKey:@"user"] valueForKey:@"name"];
    
    return YES;
}

@end
