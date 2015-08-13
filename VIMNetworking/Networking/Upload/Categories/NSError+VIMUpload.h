//
//  NSError+VIMUpload.h
//  Pods
//
//  Created by Hanssen, Alfie on 7/30/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VIMUploadErrorCode)
{
    VIMUploadErrorCodeInsufficientLocalStorage = 10000,
};

extern NSString *const VIMTempFileMakerErrorDomain;
extern NSString *const VIMUploadFileTaskErrorDomain;
extern NSString *const VIMCreateRecordTaskErrorDomain;
extern NSString *const VIMMetadataTaskErrorDomain;
extern NSString *const VIMActivateRecordTaskErrorDomain;

@interface NSError (VIMUpload)

+ (NSError *)errorWithError:(NSError *)error domain:(NSString *)domain URLResponse:(NSURLResponse *)response;

- (BOOL)isInsufficientLocalStorageError;

@end
