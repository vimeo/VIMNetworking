//
//  NSError+BaseError.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/14/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "NSError+BaseError.h"

NSString * const VimeoErrorCodeHeaderKey = @"Vimeo-Error-Code";
NSString * const VimeoErrorCodeKey = @"VimeoErrorCode";
NSString * const VimeoErrorDomainKey = @"VimeoErrorDomain";

NSString *const BaseErrorKey = @"BaseError";
NSString *const AFNetworkingErrorDomain = @"AFNetworkingErrorDomain";
NSString * const kVimeoServerErrorDomain = @"VimeoServerErrorDomain";

@implementation NSError (BaseError)

//+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message
//{
//    NSDictionary *userInfo = nil;
//    if (message)
//    {
//        userInfo = @{ NSLocalizedDescriptionKey: message };
//    }
//    
//    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
//}
//
//+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code baseError:(NSError *)baseError
//{
//    NSDictionary *userInfo = nil;
//    if (baseError)
//    {
//        userInfo = @{ BaseErrorKey: baseError };
//    }
//    
//    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
//}

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

+ (NSError *)vimeoErrorFromError:(NSError *)error withVimeoDomain:(NSString *)vimeoDomain vimeoErrorCode:(NSInteger)vimeoErrorCode
{
    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    
    mutableUserInfo[VimeoErrorCodeKey] = @(vimeoErrorCode);
    mutableUserInfo[VimeoErrorDomainKey] = vimeoDomain;
    
    return [NSError errorWithDomain:error.domain code:error.code userInfo:mutableUserInfo];
}

@end
