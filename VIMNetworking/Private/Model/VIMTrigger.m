//
//  VIMTrigger.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 10/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTrigger.h"

@interface VIMTrigger ()

@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *action;

@end

@implementation VIMTrigger

- (NSDictionary *)getObjectMapping
{
    return @{@"context_type": @"contextType",
             @"context_uri": @"contextUri"};
}

- (BOOL)isEnabled
{
    return [self.status isEqualToString:@"enabled"];
}

@end
