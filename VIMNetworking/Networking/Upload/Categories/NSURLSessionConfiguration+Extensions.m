//
//  NSURLSessionConfiguration+Extensions.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "NSURLSessionConfiguration+Extensions.h"

@implementation NSURLSessionConfiguration (Extensions)

+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithID:(NSString *)sessionID sharedContainerID:(NSString *)sharedContainerID
{
    NSAssert(sessionID, @"Invalid session ID");
    
    NSURLSessionConfiguration *sessionConfiguration = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if ([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)])
    {
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionID];
    }
    else
    {
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionID];
    }
    
    if (sharedContainerID)
    {
        if([sessionConfiguration respondsToSelector:@selector(setSharedContainerIdentifier:)])
        {
            [sessionConfiguration setSharedContainerIdentifier:sharedContainerID];
        }
    }
    
#else
    sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionID];
#endif
    
    return sessionConfiguration;
}

@end
