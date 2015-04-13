//
//  ECAccountManager.h
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
