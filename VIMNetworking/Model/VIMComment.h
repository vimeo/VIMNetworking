//
//  VIMComment.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMUser;

@interface VIMComment : VIMModelObject

@property (nonatomic, strong) VIMUser *user;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSDate *dateCreated;

@property (nonatomic, strong) NSNumber *totalReplies;
@property (nonatomic, copy) NSString *repliesURI;

@end
