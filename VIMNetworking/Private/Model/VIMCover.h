//
//  VIMCover.h
//  VIMCore
//
//  Created by Kashif Muhammad on 2/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMCover : VIMModelObject

@property (nonatomic, strong) NSNumber *active;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *uri;

+ (VIMCover *)selectActiveCover:(NSArray *)covers;

@end
