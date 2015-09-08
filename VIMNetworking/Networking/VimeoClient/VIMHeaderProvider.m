//
//  VIMHeaderProvider.m
//  VIMUpload
//
//  Created by Hanssen, Alfie on 9/2/15.
//  Copyright (c) 2015 Vimeo (https://vimeo.com)
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

#import "VIMHeaderProvider.h"
#import "VIMSessionConfiguration.h"
#import <UIKit/UIKit.h>

NSString *const AcceptHeaderKey = @"Accept";
NSString *const UserAgentHeaderKey = @"User-Agent";
NSString *const AuthorizationHeaderKey = @"Authorization";

@implementation VIMHeaderProvider

+ (NSString *)defaultUserAgentString
{
    NSString *userAgent = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f; Version %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    
#endif
#pragma clang diagnostic pop
    
    if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding])
    {
        NSMutableString *mutableUserAgent = [userAgent mutableCopy];
        if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false))
        {
            userAgent = mutableUserAgent;
        }
    }
    
    return userAgent;
}

+ (NSString *)defaultAcceptHeaderValue
{
    return [VIMHeaderProvider acceptHeaderValueWithAPIVersionString:DefaultAPIVersionString];
}

+ (nonnull NSString *)acceptHeaderValueWithAPIVersionString:(nonnull NSString *)APIVersionString
{
    return [NSString stringWithFormat:@"application/vnd.vimeo.*+json; version=%@", APIVersionString];
}

@end
