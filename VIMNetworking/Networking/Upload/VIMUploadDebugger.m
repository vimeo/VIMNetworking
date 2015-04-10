//
//  Debugger.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMUploadDebugger.h"

#import <UIKit/UIKit.h>

#define LOCAL_NOTIFICATIONS_ENABLED 1

@implementation VIMUploadDebugger

+ (void)postLocalNotificationWithContext:(NSString *)context message:(NSString *)message
{
    NSString *modMessage = [NSString stringWithFormat:@"%@--%@", [VIMUploadDebugger debugContext:context], message];
    
    [VIMUploadDebugger postLocalNotificationWithMessage:modMessage];
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
    if ([context containsString:@"app"])
    {
        return @"app";
    }
    else if ([context containsString:@"ext"])
    {
        return @"ext";
    }
    else
    {
        return @"-";
    }
}

@end
