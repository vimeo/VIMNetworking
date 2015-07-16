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
    
    VIMErrorCodeInvalidRequestInput = 2204, // root error code for all invalid parameters errors below
    
    VIMErrorCodeWrongEmailPassword = 2207,
    VIMErrorCodeEmailTooLong = 2217,
    VIMErrorCodePasswordTooShort = 2211,
    VIMErrorCodePasswordTooSimple = 2212,
    VIMErrorCodeNameInPassword = 2213,
    VIMErrorCodeEmailNotRecognized = 2218,
    VIMErrorCodePasswordEmailMismatch = 2219,
    VIMErrorCodeNoPasswordProvided = 2210,
    VIMErrorCodeNoEmailProvided = 2215,
    VIMErrorCodeInvalidEmail = 2216,
    VIMErrorCodeNoNameProvided = 2214,
    VIMErrorCodeNameTooLong = 2209,
    VIMErrorCodeFacebookJoinInvalidToken = 2303,
    VIMErrorCodeFacebookJoinNoToken = 2306,
    VIMErrorCodeFacebookJoinMissingProperty = 2304,
    VIMErrorCodeFacebookJoinMalformedToken = 2305,
    VIMErrorCodeFacebookJoinDecryptFail = 2307,
    VIMErrorCodeFacebookJoinTokenTooLong = 2308,
    VIMErrorCodeFacebookLoginNoToken = 2312,
    VIMErrorCodeFacebookLoginMissingProperty = 2310,
    VIMErrorCodeFacebookLoginMalformedToken = 2311,
    VIMErrorCodeFacebookLoginDecryptFail = 2313,
    VIMErrorCodeFacebookLoginTokenTooLong = 2314,
    VIMErrorCodeFacebookInvalidInputGrantType = 2221,
    VIMErrorCodeFacebookJoinValidateTokenFail = 2315,
    VIMErrorCodeFacebookInvalidNoInput = 2208,
    VIMErrorCodeFacebookInvalidToken = 2300,
    VIMErrorCodeFacebookMissingProperty = 2301,
    VIMErrorCodeFacebookMalformedToken = 2302,
    VIMErrorCodeEmailAlreadyRegistered = 2400,
    VIMErrorCodeEmailBlocked = 2401,
    VIMErrorCodeEmailSpammer = 2402,
    VIMErrorCodeEmailPurgatory = 2403,
    VIMErrorCodeURLUnavailable = 2404,
    VIMErrorCodeTimeout = 5000,
    VIMErrorCodeTokenNotGenerated = 5001
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
