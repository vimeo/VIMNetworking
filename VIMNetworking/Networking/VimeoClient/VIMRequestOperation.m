//
//  VIMRequestOperation.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/15/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMRequestOperation.h"

@implementation VIMRequestOperation

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super initWithRequest:urlRequest];
    if (self)
    {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    
    return self;
}

@end
