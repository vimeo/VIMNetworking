//
//  VIMAPIConfiguration.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 10/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMAPIConfiguration.h"

#import "VIMSession.h"

@implementation VIMAPIConfiguration

- (void)didFinishMapping
{
    if (self.host == nil || ![self.host isKindOfClass:[NSString class]])
    {
        self.host = VimeoBaseURLString;
    }
}

@end
