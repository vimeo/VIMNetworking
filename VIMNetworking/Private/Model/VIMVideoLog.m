//
//  VIMVideoLog.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMVideoLog.h"

@interface VIMVideoLog ()

@property (nonatomic, copy, readwrite) NSString *playURLString;
@property (nonatomic, copy, readwrite) NSString *loadURLString;
@property (nonatomic, copy, readwrite) NSString *likeURLString;
@property (nonatomic, copy, readwrite) NSString *watchLaterURLString;

@end

@implementation VIMVideoLog

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"play": @"playURLString",
             @"load": @"loadURLString",
             @"like_press" : @"likeURLString",
             @"watchlater_press" : @"watchLaterURLString"};
}

@end
