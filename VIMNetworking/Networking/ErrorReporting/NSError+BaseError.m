//
//  NSError+BaseError.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/14/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "NSError+BaseError.h"

NSString *const BaseErrorKey = @"BaseError";
NSString *const AFNetworkingErrorDomain = @"AFNetworkingErrorDomain";
NSString * const kVimeoServerErrorDomain = @"VimeoServerErrorDomain";

@implementation NSError (BaseError)

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message
{
    NSDictionary *userInfo = nil;
    if (message)
    {
        userInfo = @{ NSLocalizedDescriptionKey: message };
    }
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code baseError:(NSError *)baseError
{
    NSDictionary *userInfo = nil;
    if (baseError)
    {
        userInfo = @{ BaseErrorKey: baseError };
    }
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSError *)errorFromServerError:(NSError *)error withNewDomain:(NSString *)newDomain
{
    if([error.domain isEqualToString:AFNetworkingErrorDomain])
    {
        if(error.localizedRecoverySuggestion && error.localizedRecoverySuggestion.length > 0)
        {
            NSString *errorStr = error.localizedRecoverySuggestion;
            
            NSData *data = [error.localizedRecoverySuggestion dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *JSONError = nil;
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
            if(JSONError == nil && JSON && [JSON isKindOfClass:[NSDictionary class]])
            {
                NSString *serverErrorMsg = [JSON objectForKey:@"error"];
                if(serverErrorMsg)
                    errorStr = serverErrorMsg;
            }
            
            if(errorStr)
            {
                return [NSError errorWithDomain:newDomain code:1 userInfo:[NSDictionary dictionaryWithObject:errorStr forKey:NSLocalizedDescriptionKey]];
            }
        }
    }
    
    return nil;
}

@end
