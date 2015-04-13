//
//  VIMOAuthAuthenticator.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/30/13.
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
