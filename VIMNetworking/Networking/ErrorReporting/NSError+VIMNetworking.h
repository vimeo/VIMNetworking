//
//  NSError+VIMNetworking.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VIMErrorCode)
{
    VIMErrorCodeUploadStorageQuotaExceeded = 4101,
    VIMErrorCodeUploadDailyQuotaExceeded = 4102,
    
    VIMErrorCodeEmailMalformed = 4207, // TODO; add real error codes
    VIMErrorCodeEmailTooLong = 42071,
    VIMErrorCodePasswordInsecure = 42072,  // when a password is shorter than 8 chars or doesn't contain 4 unique chars
    VIMErrorCodePasswordContainsInsecureText = 42073, // when a password contains the username or email
    VIMErrorCodePasswordVeryInsecure = 42074, // both of the two preceding error conditions above are present
    VIMErrorCodeCredentialsRejected = 42075  // Username and/or password are incorrect
};

typedef NS_ENUM(NSInteger, HTTPErrorCode)
{
    HTTPErrorCodeServiceUnavailable = 503,
    HTTPErrorCodeUnauthorized = 401,
    HTTPErrorCodeForbidden = 403
};

@interface NSError (VIMNetworking)

#pragma mark - User Presentable Errors

- (NSString *)presentableTitle;
- (NSString *)presentableDescription;

#pragma mark - Error Types

- (BOOL)isServiceUnavailableError;

- (BOOL)isInvalidTokenError;

- (BOOL)isForbiddenError;

- (BOOL)isUploadQuotaError;
- (BOOL)isUploadQuotaDailyExceededError;
- (BOOL)isUploadQuotaStorageExceededError;

@end
