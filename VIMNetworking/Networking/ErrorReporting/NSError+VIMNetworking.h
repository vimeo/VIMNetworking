//
//  NSError+VIMNetworking.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, VIMErrorCode)
//{
//    VIMErrorCodeUploadStorageQuotaExceeded = 4101,
//    VIMErrorCodeUploadDailyQuotaExceeded = 4102,
//    
//    VIMErrorCodeInvalidRequestInput = 2204, // root error code for all invalid parameters errors below
//    
//    VIMErrorCodeVideoPasswordIncorrect = 2222,
//    VIMErrorCodeNoVideoPasswordProvided = 2223,
//    
//    VIMErrorCodeEmailTooLong = 2216,
//    VIMErrorCodePasswordTooShort = 2210,
//    VIMErrorCodePasswordTooSimple = 2211,
//    VIMErrorCodeNameInPassword = 2212,
//    VIMErrorCodeEmailNotRecognized = 2217,
//    VIMErrorCodePasswordEmailMismatch = 2218,
//    VIMErrorCodeNoPasswordProvided = 2209,
//    VIMErrorCodeNoEmailProvided = 2214,
//    VIMErrorCodeInvalidEmail = 2215,
//    VIMErrorCodeNoNameProvided = 2213,
//    VIMErrorCodeNameTooLong = 2208,
//    VIMErrorCodeFacebookJoinInvalidToken = 2303,
//    VIMErrorCodeFacebookJoinNoToken = 2306,
//    VIMErrorCodeFacebookJoinMissingProperty = 2304,
//    VIMErrorCodeFacebookJoinMalformedToken = 2305,
//    VIMErrorCodeFacebookJoinDecryptFail = 2307,
//    VIMErrorCodeFacebookJoinTokenTooLong = 2308,
//    VIMErrorCodeFacebookLoginNoToken = 2312,
//    VIMErrorCodeFacebookLoginMissingProperty = 2310,
//    VIMErrorCodeFacebookLoginMalformedToken = 2311,
//    VIMErrorCodeFacebookLoginDecryptFail = 2313,
//    VIMErrorCodeFacebookLoginTokenTooLong = 2314,
//    VIMErrorCodeFacebookInvalidInputGrantType = 2221,
//    VIMErrorCodeFacebookJoinValidateTokenFail = 2315,
//    VIMErrorCodeFacebookInvalidNoInput = 2207,
//    VIMErrorCodeFacebookInvalidToken = 2300,
//    VIMErrorCodeFacebookMissingProperty = 2301,
//    VIMErrorCodeFacebookMalformedToken = 2302,
//    VIMErrorCodeEmailAlreadyRegistered = 2400,
//    VIMErrorCodeEmailBlocked = 2401,
//    VIMErrorCodeEmailSpammer = 2402,
//    VIMErrorCodeEmailPurgatory = 2403,
//    VIMErrorCodeURLUnavailable = 2404,
//    VIMErrorCodeDRMStreamLimitHit = 3420,
//    VIMErrorCodeDRMDeviceLimitHit = 3421,
//    VIMErrorCodeTimeout = 5000,
//    VIMErrorCodeTokenNotGenerated = 5001,
//};
//
//typedef NS_ENUM(NSInteger, HTTPErrorCode)
//{
//    HTTPErrorCodeServiceUnavailable = 503,
//    HTTPErrorCodeUnauthorized = 401,
//    HTTPErrorCodeForbidden = 403
//};
//
//extern NSString * const __nonnull VimeoErrorCodeHeaderKey;
//extern NSString * const __nonnull VimeoErrorCodeKeyLegacy;

@interface NSError (VIMNetworking)

//#pragma mark - Error Types
//
//- (BOOL)isServiceUnavailableError;
//- (BOOL)isInvalidTokenError;
//- (BOOL)isOfflineError;
//
//#pragma mark - Helpers
//
//- (NSInteger)statusCode;
//- (NSInteger)vimeoServerErrorCode;
//- (NSInteger)vimeoInvalidParametersFirstErrorCode;
//- (nonnull NSArray *)vimeoInvalidParametersErrorCodes;
//- (nullable NSDictionary *)errorResponseBodyJSON;
//- (nullable NSString *)vimeoInvalidParametersErrorCodesString;
//- (nullable NSString *)vimeoUserMessage;
//- (nullable NSString *)vimeoDeveloperMessage;

@end