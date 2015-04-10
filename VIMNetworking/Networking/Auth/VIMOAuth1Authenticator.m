//
//  VIMOAuth1Authenticator.m
//  VIMCore
//
//  Created by Kashif Muhammad on 11/4/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMOAuth1Authenticator.h"

#import "VIMAccount.h"
#import "VIMAccountCredential.h"

#import "AFHTTPRequestOperationManager.h"
//#import "AFJSONRequestOperation.h"

#import "VIMOAuth1.h"
#import "VIMAuthHelper.h"

@interface VIMOAuth1Authenticator ()

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;

@end

@implementation VIMOAuth1Authenticator

- (id)initWithURL:(NSString *)url clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret
{
    self = [super init];
    if (self)
    {
        self.url = url;
        self.clientID = clientID;
        self.clientSecret = clientSecret;
    }
    
    return self;
}

- (void)authenticateAccount:(VIMAccount *)account username:(NSString *)username password:(NSString *)password completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    account.username = username;
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    
    [mutableParameters setValue:@"client_auth" forKey:@"x_auth_mode"];
    [mutableParameters setValue:username forKey:@"x_auth_username"];
    [mutableParameters setValue:password forKey:@"x_auth_password"];
    
    [self authenticateAccount:account parameters:mutableParameters completionBlock:completionBlock];
}

- (void)authenticateAccount:(VIMAccount *)account parameters:(NSDictionary *)parameters completionBlock:(void (^)(id responseObject, NSError *error))completionBlock
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    [mutableParameters setObject:self.clientID forKey:@"client_id"];
    [mutableParameters setObject:self.clientSecret forKey:@"client_secret"];
    
    parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    
//	AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:self.url]];

//    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:parameters];
    
    AFHTTPRequestOperationManager *client = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:self.url]];
    client.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Authorize request

    VIMAccountCredential *credential = [[VIMAccountCredential alloc] init];
    credential.clientID = self.clientID;
    credential.clientSecret = self.clientSecret;

    VIMOAuth1 *auth = [[VIMOAuth1 alloc] initWithCredential:credential];
    [auth authorizeRequest:request withParameters:parameters];

//    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
    [client POST:nil parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *attributes = VIMParametersFromQueryString(operation.responseString);
		
        VIMAccountCredential *credential = [[VIMAccountCredential alloc] init];
        
        credential.clientID = self.clientID;
        credential.clientSecret = self.clientSecret;
        
		credential.accessToken = [attributes objectForKey:@"oauth_token"];
		credential.secret = [attributes objectForKey:@"oauth_token_secret"];
		credential.session = [attributes objectForKey:@"oauth_session_handle"];
        
		NSDate *expirationDate = nil;
		if (attributes[@"oauth_token_duration"])
			expirationDate = [NSDate dateWithTimeIntervalSinceNow:[[attributes objectForKey:@"oauth_token_duration"] doubleValue]];
		
		BOOL renewable = NO;
		if (attributes[@"oauth_token_renewable"])
			renewable = VIMQueryStringValueIsTrue([attributes objectForKey:@"oauth_token_renewable"]);
        
		credential.renewable = renewable;
		credential.expirationDate = expirationDate;
        
        account.credential = credential;
        account.serverResponse = responseObject;

        if (completionBlock)
            completionBlock(responseObject, nil);
		
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
		if (completionBlock)
            completionBlock(nil, error);
    }];
	
    [client enqueueHTTPRequestOperation:operation];
}

@end
