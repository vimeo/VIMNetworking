//
//  VIMVimeoSessionConfiguration.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMSessionConfiguration.h"
#import <Foundation/Foundation.h>

@implementation VIMSessionConfiguration

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _APIVersionString = @"3.2";
    }
    
    return self;
}

#pragma mark - Public API

- (BOOL)isValid
{
    NSParameterAssert(self.clientKey && self.clientSecret && self.scope);
    
    return self.clientKey && self.clientSecret && self.scope;
}

@end
