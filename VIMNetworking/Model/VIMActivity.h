//
//  VIMActivity.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/26/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMVideo;
@class VIMUser;
@class VIMChannel;
@class VIMGroup;
@class VIMTag;

@interface VIMActivity : VIMModelObject

@property (nonatomic, strong) VIMVideo *video;
@property (nonatomic, strong) VIMUser *user;
@property (nonatomic, strong) VIMChannel *channel;
@property (nonatomic, strong) VIMGroup *group;
@property (nonatomic, strong) VIMTag *tag;

@property (nonatomic, copy) NSString *uri;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) NSDate *time;

@end
