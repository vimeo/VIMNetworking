//
//  VIMSessionNew.h
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/19/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMAccount;
@class VIMSessionConfiguration;
@class VIMAuthenticator;
@class VIMClient;

@interface VIMSessionNew : NSObject

@property (nonatomic, strong, readonly) VIMSessionConfiguration *configuration;
@property (nonatomic, strong, readonly) VIMAccount *account;
@property (nonatomic, strong, readonly) VIMAuthenticator *authenticator;
@property (nonatomic, strong, readonly) VIMClient *client;

+ (void)setupWithConfiguration:(VIMSessionConfiguration *)configuration;

+ (instancetype)sharedSession;

@end
