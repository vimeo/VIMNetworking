//
//  VIMActivity.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/26/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMActivity.h"
#import "VIMVideo.h"
#import "VIMUser.h"
#import "VIMChannel.h"
#import "VIMGroup.h"
#import "VIMTag.h"
#import "NSString+MD5.h"

@implementation VIMActivity

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"clip" : @"video"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"clip"])
        return [VIMVideo class];

    if([key isEqualToString:@"user"])
        return [VIMUser class];

    if([key isEqualToString:@"channel"])
        return [VIMChannel class];

    if([key isEqualToString:@"group"])
        return [VIMGroup class];
    
    if([key isEqualToString:@"tag"])
        return [VIMTag class];

    return nil;
}

- (void)didFinishMapping
{
    self.objectID = [self.uri MD5];

    if([self.time isKindOfClass:[NSString class]])
        self.time = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.time];
}

@end
