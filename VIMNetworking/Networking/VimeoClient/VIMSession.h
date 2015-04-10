//
//  VIMVimeoSession.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
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
- (VIMCache *)appGroupUserCache;

- (NSString *)appGroupTmpPath;
- (NSString *)appGroupExportsDirectory;

- (NSString *)backgroundSessionIdentifierApp;
- (NSString *)backgroundSessionIdentifierExtension;
- (NSString *)sharedContainerID;

@end
