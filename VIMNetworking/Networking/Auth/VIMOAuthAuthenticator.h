//
//  VIMOAuthAuthenticator.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/30/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/ACAccount.h>

@class VIMAccount;

extern NSString * const kVIMOAuthGrantType_AuthorizationCode;
extern NSString * const kVIMOAuthGrantType_ClientCredentials;
extern NSString * const kVIMOAuthGrantType_Password;
extern NSString * const kVIMOAuthGrantType_RefreshToken;

@interface VIMOAuthAuthenticator : NSObject

@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *clientID;
@property (nonatomic, copy, readonly) NSString *clientSecret;

@property (nonatomic, strong) ACAccount *ac_account;

- (instancetype)initWithURL:(NSString *)url clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret;

- (NSOperation *)authenticateAccount:(VIMAccount *)account email:(NSString *)email password:(NSString *)password scope:(NSString *)scope completionBlock:(void (^)(id responseObject, NSError *error))completionBlock;

- (NSOperation *)authenticateAccount:(VIMAccount *)account code:(NSString *)code redirectURI:(NSString *)redirectURI completionBlock:(void (^)(id responseObject, NSError *error))completionBlock;

- (NSOperation *)authenticateAccount:(VIMAccount *)account parameters:(NSDictionary *)parameters completionBlock:(void (^)(id responseObject, NSError *error))completionBlock;

- (BOOL)authenticateAccount:(VIMAccount *)account withJSONResponse:(id)JSON;

@end
