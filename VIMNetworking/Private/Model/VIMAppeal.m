//
//  VIMAppeal.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/24/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMAppeal.h"

static NSString *Denied = @"denied"; // flagged (normal status)

@interface VIMAppeal ()

@property (nonatomic, copy) NSString *status;
@property (nonatomic, assign, readwrite) VIMCopyrightMatchStatus copyrightMatchStatus;

@end

@implementation VIMAppeal

- (void)didFinishMapping
{
    self.copyrightMatchStatus = [self determineCopyrightMatchStatus];
}

- (VIMCopyrightMatchStatus)determineCopyrightMatchStatus
{
    if ([self.status isKindOfClass:[NSString class]] && [self.status isEqualToString:Denied])
    {
        return VIMCopyrightMatchStatusDenied;
    }
    
    return VIMCopyrightMatchStatusNone;
}


@end
