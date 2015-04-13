//
//  Debugger.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/5/15.
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

#import "VIMTaskQueueDebugger.h"

#import <UIKit/UIKit.h>

#define LOCAL_NOTIFICATIONS_ENABLED 1

@implementation VIMTaskQueueDebugger

+ (void)postLocalNotificationWithContext:(NSString *)context message:(NSString *)message
{
    NSString *modMessage = [NSString stringWithFormat:@"%@--%@", [VIMTaskQueueDebugger debugContext:context], message];
    
    [VIMTaskQueueDebugger postLocalNotificationWithMessage:modMessage];
}

+ (void)postLocalNotificationWithMessage:(NSString *)message
{
    NSLog(@"%@", message);

#if LOCAL_NOTIFICATIONS_ENABLED
    
#ifndef UPLOAD_EXTENSION
    
    dispatch_async(dispatch_get_main_queue(), ^{

        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.alertBody = message;
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        
    });

#endif
    
#endif
    
}

+ (NSString *)debugContext:(NSString *)context
{
    NSRange range = [context rangeOfString:@"app"];
    if (range.location != NSNotFound)
    {
        return @"app";
    }
    
    range = [context rangeOfString:@"ext"];
    if (range.location != NSNotFound)
    {
        return @"ext";
    }

    return @"";
}

@end
