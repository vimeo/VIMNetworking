//
//  VIMVideoLog.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VIMModelObject.h"

@interface VIMVideoLog : VIMModelObject

@property (nonatomic, copy, readonly) NSString *playURLString;
@property (nonatomic, copy, readonly) NSString *loadURLString;
@property (nonatomic, copy, readonly) NSString *likeURLString;
@property (nonatomic, copy, readonly) NSString *watchLaterURLString;

@end
