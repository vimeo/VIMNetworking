//
//  VIMPreference.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/16/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMPreference.h"
#import "VIMVideoPreference.h"

@implementation VIMPreference

#pragma mark - VIMMappable

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"videos"])
    {
        return [VIMVideoPreference class];
    }
    
    return nil;
}

@end
