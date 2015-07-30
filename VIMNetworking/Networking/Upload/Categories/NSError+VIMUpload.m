//
//  NSError+VIMUpload.m
//  Pods
//
//  Created by Hanssen, Alfie on 7/30/15.
//
//

#import "NSError+VIMUpload.h"

NSString *const VIMTempFileMakerErrorDomain = @"VIMTempFileMakerErrorDomain";
NSString *const VIMUploadFileTaskErrorDomain = @"VIMUploadFileTaskErrorDomain";
NSString *const VIMCreateRecordTaskErrorDomain = @"VIMCreateRecordTaskErrorDomain";
NSString *const VIMMetadataTaskErrorDomain = @"VIMMetadataTaskErrorDomain";
NSString *const VIMActivateRecordTaskErrorDomain = @"VIMActivateRecordTaskErrorDomain";

@implementation NSError (VIMUpload)

- (BOOL)isInsufficientLocalStorageError
{
    return self.code == VIMUploadErrorCodeInsufficientLocalStorage;
}

@end
