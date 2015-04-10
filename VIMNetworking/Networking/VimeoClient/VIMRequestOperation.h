//
//  VIMRequestOperation.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/15/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"
#import "VIMRequestToken.h"

@class VIMRequestDescriptor;

@interface VIMRequestOperation : AFHTTPRequestOperation <VIMRequestToken>

@property (nonatomic, strong) VIMRequestDescriptor *descriptor;

@property (nonatomic, weak) id handler;

@end

