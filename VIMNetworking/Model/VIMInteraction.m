//
//  VIMInteraction.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/23/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMInteraction.h"

// Interaction names

NSString * const VIMInteractionNameWatchLater = @"watchlater";
NSString * const VIMInteractionNameFollow = @"follow";
NSString * const VIMInteractionNameLike = @"like";

@implementation VIMInteraction

#pragma mark - VIMMappable

- (void)didFinishMapping
{
    if ([self.added_time isKindOfClass:[NSString class]])
    {
        self.added_time = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.added_time];
    }
}

@end
