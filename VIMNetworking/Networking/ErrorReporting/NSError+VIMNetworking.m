//
//  NSError+VIMNetworking.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "NSError+VIMNetworking.h"
#import "NSError+BaseError.h"
#import "AFURLResponseSerialization.h"

@implementation NSError (VIMNetworking)

- (BOOL)isServiceUnavailableError
{
    NSError *baseError = self;
    if (self.userInfo[BaseErrorKey])
    {
        baseError = self.userInfo[BaseErrorKey];
    }
    
    NSHTTPURLResponse *urlResponse = baseError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse && [urlResponse statusCode] == 503)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)isInvalidTokenError
{
    NSError *baseError = self;
    if (self.userInfo[BaseErrorKey])
    {
        baseError = self.userInfo[BaseErrorKey];
    }
    
    NSHTTPURLResponse *urlResponse = baseError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse && [urlResponse statusCode] == 401)
    {
        NSString *header = urlResponse.allHeaderFields[@"WWW-Authenticate"];
        if ([header isEqualToString:@"Bearer error=\"invalid_token\""])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isForbiddenError
{
    NSError *baseError = self;
    if (self.userInfo[BaseErrorKey])
    {
        baseError = self.userInfo[BaseErrorKey];
    }
    
    NSHTTPURLResponse *urlResponse = baseError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse && [urlResponse statusCode] == 403)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)isUploadQuotaError
{
    NSNumber *errorCodeNumber = self.userInfo[VimeoErrorCodeKey];
    if (errorCodeNumber)
    {
        NSInteger errorCode = [errorCodeNumber integerValue];
        
        return errorCode == VIMErrorCodeUploadDailyQuotaExceeded || errorCode == VIMErrorCodeUploadStorageQuotaExceeded;
    }
    
    return NO;
}

- (BOOL)isUploadQuotaDailyExceededError
{
    NSNumber *errorCodeNumber = self.userInfo[VimeoErrorCodeKey];
    if (errorCodeNumber)
    {
        NSInteger errorCode = [errorCodeNumber integerValue];
        
        return errorCode == VIMErrorCodeUploadDailyQuotaExceeded;
    }
    
    return NO;
}

- (BOOL)isUploadQuotaStorageExceededError
{
    NSNumber *errorCodeNumber = self.userInfo[VimeoErrorCodeKey];
    if (errorCodeNumber)
    {
        NSInteger errorCode = [errorCodeNumber integerValue];
        
        return errorCode == VIMErrorCodeUploadStorageQuotaExceeded;
    }
    
    return NO;
}

@end
