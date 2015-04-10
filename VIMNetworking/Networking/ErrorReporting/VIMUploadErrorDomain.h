//
//  VIMUploadErrorDomain.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMErrorDomain.h"

@interface VIMUploadErrorDomain : VIMErrorDomain

extern NSString *const VIMNetworkingUploadErrorDomain;

typedef NS_ENUM(NSUInteger, VIMNetworkingUploadErrorCodes)
{
    UnableToCreateRecordErrorCode = 0,
    UnableToCopyFileErrorCode,
    FailedUploadErrorCode,
    UnableToCompleteUploadErrorCode,
    UnableToRemoveFileErrorCode,
    UnableToSetMetadataErrorCode,
    GenericCompositeUploadTaskErrorCode,
};

extern NSString *const UnableToCreateRecordErrorType;
extern NSString *const InsufficientUploadQuotaErrorType;
extern NSString *const UnableToGetAssetErrorType;
extern NSString *const UnableToReadMemoryErrorType;
extern NSString *const InsufficientMemoryErrorType;
extern NSString *const FailedUploadErrorType;
extern NSString *const PrivacyNotSetErrorType;

@end
