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

#pragma mark - User Presentable Errors

- (NSString *)presentableTitle
{
    NSString *title = nil;
    
    NSInteger errorCode = [self serverErrorCode];
    
    switch (errorCode)
    {
        case VIMErrorCodePasswordInsecure:
        case VIMErrorCodePasswordContainsInsecureText:
        case VIMErrorCodePasswordVeryInsecure:
        case VIMErrorCodeEmailMalformed:
        case VIMErrorCodeEmailTooLong:
            title = NSLocalizedString(@"InvalidEmailPassword", nil);
            break;
            
        default: // not found
            title = nil;
            break;
    }
    
    return title;
}

- (NSString *)presentableDescription
{
    NSString *description = nil;
    
    NSInteger errorCode = [self serverErrorCode];
    
    switch (errorCode)
    {
        case VIMErrorCodeEmailMalformed:
            description = NSLocalizedString(@"EmailRequired", nil);
            break;
        case VIMErrorCodeEmailTooLong:
            description = NSLocalizedString(@"EmailLengthErrorMessage", nil);
            break;
        case VIMErrorCodePasswordInsecure:
            description = NSLocalizedString(@"PasswordLengthErrorMessage", nil);
            break;
        case VIMErrorCodePasswordContainsInsecureText:
            description = NSLocalizedString(@"PasswordUniquenessErrorMessage", nil);
            break;
        case VIMErrorCodePasswordVeryInsecure:
            description = NSLocalizedString(@"PasswordLengthAndUniquenessErrorMessage", nil);
            break;
            
        default: // not found
            description = nil;
            break;
    }
    
    return description;
}

#pragma mark - Error Types

- (BOOL)isServiceUnavailableError
{
    return [self statusCode] == HTTPErrorCodeServiceUnavailable;
}

- (BOOL)isInvalidTokenError
{
    NSError *baseError = self;
    if (self.userInfo[BaseErrorKey])
    {
        baseError = self.userInfo[BaseErrorKey];
    }
    
    NSHTTPURLResponse *urlResponse = baseError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
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
    NSError *baseError = self;
    if (self.userInfo[BaseErrorKey])
    {
        baseError = self.userInfo[BaseErrorKey];
    }
    
    NSHTTPURLResponse *urlResponse = baseError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
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
    
    return 0;
}

@end
