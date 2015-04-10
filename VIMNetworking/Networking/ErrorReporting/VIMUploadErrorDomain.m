//
//  VIMUploadErrorDomain.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMUploadErrorDomain.h"

@implementation VIMUploadErrorDomain

NSString *const VIMNetworkingUploadErrorDomain = @"VIMNetworkingUploadErrorDomain";

NSString *const UnableToCreateRecordErrorType = @"UnableToCreateRecordErrorType";
NSString *const InsufficientUploadQuotaErrorType = @"InsufficientUploadQuotaErrorType";
NSString *const UnableToGetAssetErrorType = @"UnableToGetAssetErrorType";
NSString *const UnableToReadMemoryErrorType = @"UnableToReadMemoryErrorType";
NSString *const InsufficientMemoryErrorType = @"InsufficientMemoryErrorType";
NSString *const FailedUploadErrorType = @"FailedUploadErrorType";
NSString *const PrivacyNotSetErrorType = @"PrivacyNotSetErrorType";

+ (NSString *)domainName
{
    return VIMNetworkingUploadErrorDomain;
}

+ (NSArray *)errorTypes
{
    return @[UnableToCreateRecordErrorType, InsufficientUploadQuotaErrorType, UnableToGetAssetErrorType, UnableToReadMemoryErrorType, InsufficientMemoryErrorType, FailedUploadErrorType, PrivacyNotSetErrorType];
}

@end
