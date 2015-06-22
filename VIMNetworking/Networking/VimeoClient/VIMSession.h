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

typedef void (^VIMErrorCompletionBlock)(NSError *error);

extern NSString *const VIMSession_AuthenticatedAccountDidChangeNotification; // Posted when the account changes (log in or log out)
extern NSString *const VIMSession_AuthenticatedUserDidRefreshNotification; // Posted when the authenticated user object refreshes (user refresh)

@interface VIMSession : NSObject

@property (nonatomic, strong, readonly) VIMSessionConfiguration *configuration;
@property (nonatomic, strong, readonly) VIMAccount *account;
@property (nonatomic, strong, readonly) VIMAuthenticator *authenticator;
@property (nonatomic, strong, readonly) VIMClient *client;

+ (void)setupWithConfiguration:(VIMSessionConfiguration *)configuration;

+ (instancetype)sharedSession;

#pragma mark - Authentication

- (id<VIMRequestToken>)authenticateWithClientCredentialsGrant:(VIMErrorCompletionBlock)completionBlock;

- (id<VIMRequestToken>)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMErrorCompletionBlock)completionBlock;

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Configuration

- (void)changeBaseURL:(NSString *)baseURLString;

- (id<VIMRequestToken>)refreshAuthenticatedUserWithCompletionBlock:(VIMErrorCompletionBlock)completionBlock;

@end
