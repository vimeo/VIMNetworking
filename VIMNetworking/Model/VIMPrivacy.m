//
//  VIMPrivacy.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/24/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMPrivacy.h"

NSString *VIMPrivacy_Private = @"nobody";
NSString *VIMPrivacy_Select = @"users";
NSString *VIMPrivacy_Public = @"anybody";
NSString *VIMPrivacy_VOD = @"ptv";
NSString *VIMPrivacy_Following = @"contacts";
NSString *VIMPrivacy_Password = @"password";

@implementation VIMPrivacy

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"canAdd": @"add",
             @"canDownload" : @"download"};
}

@end
