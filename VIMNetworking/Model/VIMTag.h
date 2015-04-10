//
//  VIMTag.h
//  VIMNetworking
//
//  Created by Huebner, Rob on 11/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMTag : VIMModelObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *tag;
@property (nonatomic, copy, readonly) NSString *uri;
@property (nonatomic, copy, readonly) NSString *canonical;
@property (nonatomic, copy, readonly) NSDictionary *metadata;

@end
