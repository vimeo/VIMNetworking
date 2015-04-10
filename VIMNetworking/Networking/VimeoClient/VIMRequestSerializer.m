//
//  VIMVimeoRequestSerializer.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 8/27/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMRequestSerializer.h"
#import "VIMSession.h"
#import "VIMAccount.h"
#import "VIMAccountCredential.h"
#import "VIMSessionConfiguration.h"

@interface VIMRequestSerializer ()

@property (nonatomic, strong) VIMSession *vimeoSession;

@end

@implementation VIMRequestSerializer

+ (instancetype)serializer
{
    return nil;
}

+ (instancetype)serializerWithSession:(VIMSession *)session
{
    NSAssert(session != nil, @"Serializer must be initialized with a session object");
    
    VIMRequestSerializer *serializer = [[self alloc] init];
    serializer.writingOptions = 0;
    serializer.vimeoSession = session;
    
    [serializer setValue:[serializer JSONAcceptHeaderString] forHTTPHeaderField:@"Accept"]; // Switching from "acceptHeaderString" method

    return serializer;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f; Version %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
#endif
#pragma clang diagnostic pop
        if (userAgent)
        {
            if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding])
            {
                NSMutableString *mutableUserAgent = [userAgent mutableCopy];
                if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false))
                {
                    userAgent = mutableUserAgent;
                }
            }
            
            [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        }
    }
    
    return self;
}

#pragma mark - Requests

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    [request setValue:[self authorizationHeaderString] forHTTPHeaderField:@"Authorization"];

    return request;
}

- (NSString *)authorizationHeaderString
{
    if (self.vimeoSession.account && self.vimeoSession.account.credential)
    {
        if ([[self.vimeoSession.account.credential.tokenType lowercaseString] isEqualToString:@"bearer"])
        {
            return [NSString stringWithFormat:@"Bearer %@", self.vimeoSession.account.credential.accessToken];
        }
    }
    
    NSLog(@"MAKING BASIC AUTH REQUEST");
    
    NSString *authString = [NSString stringWithFormat:@"%@:%@", self.vimeoSession.configuration.clientKey, self.vimeoSession.configuration.clientSecret];
    
    NSData *plainData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];

    return [NSString stringWithFormat:@"Basic %@", base64String];
}

- (NSString *)JSONAcceptHeaderString
{
    if (self.vimeoSession.configuration.APIVersionString == nil)
    {
        return nil;
    }
    
    return [NSString stringWithFormat:@"application/vnd.vimeo.*+json; version=%@", self.vimeoSession.configuration.APIVersionString];
}

@end
