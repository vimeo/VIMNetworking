//
//  NSURLSessionConfiguration+Extensions.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
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
