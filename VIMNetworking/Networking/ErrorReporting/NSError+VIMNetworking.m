//
//  NSError+VIMNetworking.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "NSError+VIMNetworking.h"
#import "AFURLResponseSerialization.h"

NSString * const VimeoErrorCodeHeaderKey = @"Vimeo-Error-Code";
NSString * const VimeoErrorCodeKey = @"VimeoErrorCode";

@implementation NSError (VIMNetworking)

#pragma mark - Error Types

- (BOOL)isServiceUnavailableError
{
    return [self statusCode] == HTTPErrorCodeServiceUnavailable;
}

- (BOOL)isInvalidTokenError
{
    NSHTTPURLResponse *urlResponse = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse && [urlResponse statusCode] == HTTPErrorCodeUnauthorized)
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
    return [self statusCode] == HTTPErrorCodeForbidden;
}

- (BOOL)isUploadQuotaError
{
    return [self isUploadQuotaDailyExceededError] || [self isUploadQuotaStorageExceededError];
}

- (BOOL)isUploadQuotaDailyExceededError
{
    return [self serverErrorCode] == VIMErrorCodeUploadDailyQuotaExceeded;
}

- (BOOL)isUploadQuotaStorageExceededError
{
    return [self serverErrorCode] == VIMErrorCodeUploadStorageQuotaExceeded;
}

#pragma mark - Utilities

- (NSInteger)statusCode
{
    NSHTTPURLResponse *urlResponse = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse)
    {
        return [urlResponse statusCode];
    }
    
    return 0;
}

- (NSInteger)serverErrorCode
{
    NSNumber *errorCodeNumber = self.userInfo[VimeoErrorCodeKey];
    if (errorCodeNumber)
    {
        NSInteger errorCode = [errorCodeNumber integerValue];
        
        return errorCode;
    }
    
    NSHTTPURLResponse *response = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (response)
    {
        NSDictionary *headers = [response allHeaderFields];
        NSString *vimeoError = headers[VimeoErrorCodeHeaderKey];
        
        if (vimeoError)
        {
            return [vimeoError integerValue];
        }
    }
    
    NSDictionary *json = [self errorResponseBodyJSON];
    errorCodeNumber = [json objectForKey:@"error_code"];
    if (errorCodeNumber)
    {
        return [errorCodeNumber integerValue];
    }
    
    return NSNotFound;
}

- (NSInteger)serverInvalidParametersErrorCode
{
    NSDictionary *json = [self errorResponseBodyJSON];
    
    if (json)
    {
        NSArray *invalidParameters = json[@"invalid_parameters"];
        NSMutableArray *errorCodes = [NSMutableArray new];
        
        for (NSDictionary *errorJSON in invalidParameters)
        {
            NSString *errorCode = errorJSON[@"error_code"];
            
            if (errorCode)
            {
                [errorCodes addObject:@([errorCode integerValue])];
            }
        }
        
        return [[errorCodes firstObject] integerValue];
    }
    
    return 0;
}

- (NSDictionary *)errorResponseBodyJSON
{
    NSData *data = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (data)
    {
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (json && !error)
        {
            return json;
        }
    }
    
    return nil;
}

@end
