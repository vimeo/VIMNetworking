//
//  Debugger.h
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMUploadDebugger : NSObject

+ (void)postLocalNotificationWithContext:(NSString *)context message:(NSString *)message;
+ (void)postLocalNotificationWithMessage:(NSString *)message;

@end
