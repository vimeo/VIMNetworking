//
//  VIMVimeoSession.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
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

#import "VIMSessionConfiguration.h"

@class VIMCache;
@class VIMUser;
@class VIMAccount;

extern NSString *VimeoBaseURLString;

extern NSString *const VIMSession_DidFinishLoadingNotification;
extern NSString *const VIMSession_AuthenticatedUserDidChangeNotification; // Sent whenever authenticated user changes

@interface VIMSession : NSObject

@property (nonatomic, strong, readonly) VIMAccount *account;
@property (nonatomic, strong, readonly) VIMUser *authenticatedUser;
@property (nonatomic, strong, readonly) VIMSessionConfiguration *configuration;

+ (instancetype)sharedSession;

- (void)setupWithConfiguration:(VIMSessionConfiguration *)configuration completionBlock:(void(^)(BOOL success))completionBlock;

- (void)refreshUserFromRemoteWithCompletionBlock:(void (^)(NSError *error))completionBlock;

- (void)changeBaseURLString:(NSString *)baseURLString;

- (void)logOut;

- (NSString *)baseURLString;
- (VIMCache *)userCache; // Get local cache for current user. Returns shared cache if no current user.
- (VIMCache *)appGroupSharedCache;

- (NSString *)backgroundSessionIdentifierApp;
- (NSString *)backgroundSessionIdentifierExtension;
- (NSString *)sharedContainerID;

@end
