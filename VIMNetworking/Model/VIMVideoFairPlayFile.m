//
//  VIMVideoFairPlayFile.m
//  Vimeo
//
//  Created by King, Gavin on 7/13/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoFairPlayFile.h"

@implementation VIMVideoFairPlayFile

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    NSMutableDictionary *mapping = [[super getObjectMapping] mutableCopy];
    
    [mapping addEntriesFromDictionary:@{@"certificate_link": @"certificateLink", @"license_link": @"licenseLink"}];
    
    return mapping;
}

@end