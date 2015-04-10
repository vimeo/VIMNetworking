//
//  VIMCover.m
//  VIMCore
//
//  Created by Kashif Muhammad on 2/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMCover.h"

@implementation VIMCover

+ (VIMCover *)selectActiveCover:(NSArray *)covers
{
    for(VIMCover *cover in covers)
        if([cover.active boolValue] == YES)
            return cover;

    return nil;
}

@end
