//
//  VIMSession.h
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

#import <Foundation/Foundation.h>
#import "VIMAuthenticator.h"
#import "VIMClient.h"
#import "VIMAccount.h"
#import "VIMSessionConfiguration.h"

typedef void (^VIMErrorCompletionBlock)(NSError * __nullable error);

extern NSString *const __nonnull VIMSession_AuthenticatedAccountDidChangeNotification; // Posted when the account changes (log in or log out)
extern NSString *const __nonnull VIMSession_AuthenticatedUserDidRefreshNotification; // Posted when the authenticated user object refreshes (user refresh)

@interface VIMSession : NSObject

@property (nonatomic, strong, readonly, nonnull) VIMSessionConfiguration *configuration;
@property (nonatomic, strong, readonly, nullable) VIMAccount *account;
@property (nonatomic, strong, readonly, nonnull) VIMAuthenticator *authenticator;
@property (nonatomic, strong, readonly, nonnull) VIMClient *client;

+ (void)setupWithConfiguration:(nonnull VIMSessionConfiguration *)configuration;

+ (nullable instancetype)sharedSession;

#pragma mark - Authentication

- (nullable nullable id<VIMRequestToken>)authenticateWithClientCredentialsGrant:(nonnull VIMErrorCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)authenticateWithCodeGrantResponseURL:(nonnull NSURL *)responseURL completionBlock:(nonnull VIMErrorCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)logout;

#pragma mark - Configuration

- (BOOL)changeAccount:(nonnull VIMAccount *)account;

- (BOOL)changeBaseURL:(nonnull NSString *)baseURLString;

- (nullable id<VIMRequestToken>)refreshAuthenticatedUserWithCompletionBlock:(nullable VIMErrorCompletionBlock)completionBlock;

@end
