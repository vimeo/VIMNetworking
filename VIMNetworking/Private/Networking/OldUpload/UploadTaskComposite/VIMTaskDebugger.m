//
//  VIMNetworkTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskDebugger.h"

@implementation VIMTaskDebugger

+ (void)debugLogWithClass:(Class)invokingClass message:(NSString *)message
{
    message = [NSString stringWithFormat:@"%@: %@", NSStringFromClass(invokingClass), message];
    NSLog(@"%@", message);
    
/*
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = msg;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
*/
}

@end
