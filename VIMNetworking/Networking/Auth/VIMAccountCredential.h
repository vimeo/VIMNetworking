//
//  VIMAccountCredential.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/29/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMAccountCredential : NSObject

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *tokenType;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, copy) NSDate *expirationDate;
@property (nonatomic, copy) NSString *grantType;

- (BOOL)isUserCredential;

- (BOOL)isExpired;

@end
