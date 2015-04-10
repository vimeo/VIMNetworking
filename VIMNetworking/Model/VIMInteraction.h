//
//  VIMInteraction.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/23/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

// Interaction names

extern NSString * const VIMInteractionNameWatchLater;
extern NSString * const VIMInteractionNameFollow;
extern NSString * const VIMInteractionNameLike;

@interface VIMInteraction : VIMModelObject

@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSNumber *added;
@property (nonatomic, strong) NSDate *added_time;

@end
