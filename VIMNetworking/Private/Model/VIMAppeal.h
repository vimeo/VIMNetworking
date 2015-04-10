//
//  VIMAppeal.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/24/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

typedef NS_ENUM(NSInteger, VIMCopyrightMatchStatus)
{
    VIMCopyrightMatchStatusNone,
    VIMCopyrightMatchStatusDenied
};

@interface VIMAppeal : VIMModelObject

@property (nonatomic, copy) NSString *link;
@property (nonatomic, assign, readonly) VIMCopyrightMatchStatus copyrightMatchStatus;

@end
