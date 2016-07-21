//
//  VIMVideoDRMFiles.m
//  Vimeo
//
//  Created by King, Gavin on 7/13/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoDRMFiles.h"
#import "VIMVideoFairPlayFile.h"

@implementation VIMVideoDRMFiles

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"fairplay": @"fairPlayFile"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if( [key isEqualToString:@"fairplay"] )
    {
        return [VIMVideoFairPlayFile class];
    }
    
    return nil;
}

@end