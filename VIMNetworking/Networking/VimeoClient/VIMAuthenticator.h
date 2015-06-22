//
//  VIMAuthenticator.h
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/21/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VIMRequestOperationManager.h"

@protocol VIMRequestToken;

@class VIMAccount;

typedef void (^VIMAuthenticatorCompletionBlock)(VIMAccount *account, NSError *error);

@interface VIMAuthenticator : VIMRequestOperationManager

- (instancetype)initWithBaseURL:(NSURL *)url
                      clientKey:(NSString *)clientKey
                   clientSecret:(NSString *)clientSecret
                          scope:(NSString *)scope;

#pragma mark - URLs

- (NSURL *)codeGrantAuthorizationURL;

- (NSString *)codeGrantRedirectURI;

#pragma mark - Authentication

- (NSOperation *)authenticateWithClientCredentialsGrant:(VIMAuthenticatorCompletionBlock)completionBlock;

- (NSOperation *)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock;

// TODO: Mark these are private [AH]

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock;

- (NSOperation *)joinWithDisplayName:(NSString *)username email:(NSString *)email password:(NSString *)password completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock;

- (NSOperation *)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock;

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAuthenticatorCompletionBlock)completionBlock;

@end
