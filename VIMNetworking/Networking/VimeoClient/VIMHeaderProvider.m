//
//  VIMHeaderProvider.m
//  Pods
//
//  Created by Hanssen, Alfie on 9/2/15.
//
//

#import "VIMHeaderProvider.h"

NSString *const DefaultAPIVersionString = @"3.2";
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
