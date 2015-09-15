//
//  NSError+VIMNetworking.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "NSError+VIMNetworking.h"
#import "AFURLResponseSerialization.h"

// A numeric error code that provides direction as to why the error occurred,
// We hope that in the future these can be sunset in favor of using only VimeoErrorCodeKey (see below)
NSString * const VimeoErrorCodeHeaderKey = @"Vimeo-Error-Code";
NSString * const VimeoErrorCodeKeyLegacy = @"VimeoErrorCode";

// A numeric error code that provides direction as to why the error occurred
NSString * const VimeoErrorCodeKey = @"error_code";

// A list of numeric error codes that indicate which parameters are causing the request to fail
NSString * const VimeoInvalidParametersKey = @"invalid_parameters";

// A developer-facing message
NSString * const VimeoDeveloperMessageKey = @"developer_message";

// A user-facing message
NSString * const VimeoUserMessageKey = @"error";

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
        if (header && [header isEqualToString:@"Bearer error=\"invalid_token\""])
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
    return [self vimeoErrorCode] == VIMErrorCodeUploadDailyQuotaExceeded;
}

- (BOOL)isUploadQuotaStorageExceededError
{
    return [self vimeoErrorCode] == VIMErrorCodeUploadStorageQuotaExceeded;
}

#pragma mark - Utilities

- (NSInteger)statusCode
{
    NSHTTPURLResponse *urlResponse = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if (urlResponse)
    {
        return [urlResponse statusCode];
    }
    
    return NSNotFound;
}

- (NSInteger)vimeoErrorCode
{
    NSNumber *errorCodeNumber = self.userInfo[VimeoErrorCodeKeyLegacy];
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
    errorCodeNumber = [json objectForKey:VimeoErrorCodeKey];
    if (errorCodeNumber)
    {
        return [errorCodeNumber integerValue];
    }
    
    return NSNotFound;
}

- (NSInteger)vimeoInvalidParametersFirstErrorCode
{
    NSArray *errorCodes = [self vimeoInvalidParametersErrorCodes];
    if (errorCodes && [errorCodes count])
    {
        NSString *firstCode = [errorCodes firstObject];
        
        return [firstCode integerValue];
    }
    
    return NSNotFound;
}

- (NSArray *)vimeoInvalidParametersErrorCodes
{
    NSMutableArray *errorCodes = [NSMutableArray new];
   
    NSDictionary *json = [self errorResponseBodyJSON];
    if (json)
    {
        NSArray *invalidParameters = json[VimeoInvalidParametersKey];
        
        for (NSDictionary *errorJSON in invalidParameters)
        {
            NSString *errorCode = errorJSON[VimeoErrorCodeKey];
            if (errorCode)
            {
                [errorCodes addObject:@([errorCode integerValue])];
            }
        }
    }
    
    return errorCodes;
}

- (NSString *)vimeoInvalidParametersErrorCodesString
{
    NSString *result = nil;
    
    NSArray *errorCodes = [self vimeoInvalidParametersErrorCodes];
    if (errorCodes && [errorCodes count])
    {
        result = @"";
        
        for (int i = 0; i < [errorCodes count]; i++)
        {
            NSNumber *code = errorCodes[i];

            result = [result stringByAppendingFormat:@"%@", code];
            
            if (i < [errorCodes count] - 1)
            {
                result = [result stringByAppendingString:@"_"];
            }
        }
    }
    
    return result;
}

- (NSString *)vimeoUserMessage
{
    NSString *message = nil;
    
    NSDictionary *json = [self errorResponseBodyJSON];
    if (json)
    {
        message = json[VimeoUserMessageKey];
    }
    
    return message;
}

- (NSString *)vimeoDeveloperMessage
{
    NSString *message = nil;
    
    NSDictionary *json = [self errorResponseBodyJSON];
    if (json)
    {
        message = json[VimeoDeveloperMessageKey];
    }
    
    return message;
}

- (NSDictionary *)errorResponseBodyJSON
{
    NSData *data = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (data)
    {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (json && !error)
        {
            return json;
        }
    }
    
    return nil;
}

@end
