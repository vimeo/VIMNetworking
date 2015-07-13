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
    
    VIMErrorCodeInvalidRequestInput = 4204, // root error code for all invalid parameters errors below
    
    VIMErrorCodeEmailMalformed = 4219, // email doesn't contain @ sign
    VIMErrorCodeEmailTooLong = 4218, // email is greater than 128 characters
    VIMErrorCodePasswordInsecureShort = 4211,  // when a password is shorter than 8 chars
    VIMErrorCodePasswordInsecureSimple = 4213,  // when a password doesn't contain 4 unique chars
    VIMErrorCodePasswordInsecureContainsUserInfo = 4214, // when a password contains the username or email
    VIMErrorCodeCredentialsRejected = 4220  // Username and/or password are incorrect
};

typedef NS_ENUM(NSInteger, HTTPErrorCode)
{
    HTTPErrorCodeServiceUnavailable = 503,
    HTTPErrorCodeUnauthorized = 401,
    HTTPErrorCodeForbidden = 403
};

@interface NSError (VIMNetworking)

#pragma mark - Error Types

- (BOOL)isServiceUnavailableError;

- (BOOL)isInvalidTokenError;

- (BOOL)isForbiddenError;

- (BOOL)isUploadQuotaError;
- (BOOL)isUploadQuotaDailyExceededError;
- (BOOL)isUploadQuotaStorageExceededError;

#pragma mark - Helpers

- (NSInteger)statusCode;
- (NSInteger)serverErrorCode;
- (NSInteger)serverInvalidParametersErrorCode;
- (NSDictionary *)errorResponseBodyJSON;

@end
