//
//  NSError+VIMUpload.m
//  Pods
//
//  Created by Hanssen, Alfie on 7/30/15.
//
//

#import "NSError+VIMUpload.h"
#import "AFNetworking.h"

NSString *const VIMTempFileMakerErrorDomain = @"VIMTempFileMakerErrorDomain";
NSString *const VIMUploadFileTaskErrorDomain = @"VIMUploadFileTaskErrorDomain";
NSString *const VIMCreateRecordTaskErrorDomain = @"VIMCreateRecordTaskErrorDomain";
NSString *const VIMMetadataTaskErrorDomain = @"VIMMetadataTaskErrorDomain";
NSString *const VIMActivateRecordTaskErrorDomain = @"VIMActivateRecordTaskErrorDomain";

@implementation NSError (VIMUpload)

+ (NSError *)errorWithError:(NSError *)error domain:(NSString *)domain URLResponse:(NSURLResponse *)response
{
    if (error == nil)
    {
        return nil;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    if (error.userInfo)
    {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    
    if (response)
    {
        userInfo[AFNetworkingOperationFailingURLResponseErrorKey] = response;
    }
    
    if (domain == nil)
    {
        domain = error.domain;
    }
    
    return [NSError errorWithDomain:domain code:error.code userInfo:userInfo];
}

- (BOOL)isInsufficientLocalStorageError
{
    return self.code == VIMUploadErrorCodeInsufficientLocalStorage;
}

@end
