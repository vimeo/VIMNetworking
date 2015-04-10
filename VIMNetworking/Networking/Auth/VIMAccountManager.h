//
//  ECAccountManager.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/29/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Accounts/Accounts.h>

typedef void (^VIMAccountManagerErrorCompletionBlock)(NSError *error);

@class VIMAccount;

extern NSString * const kECAccountID_Vimeo;
extern NSString * const VIMAccountManagerErrorDomain;

@interface VIMAccountManager: NSObject

+ (VIMAccountManager *)sharedInstance;

- (NSOperation *)authenticateWithClientCredentialsGrantAndCompletionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock;

- (NSOperation *)authenticateWithCodeGrant:(NSString *)code completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock;

- (void)logoutAccount:(VIMAccount *)account;

- (void)refreshAccounts;

@end
