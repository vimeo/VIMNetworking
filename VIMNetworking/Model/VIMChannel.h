//
//  VIMChannel.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/30/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMPictureCollection;
@class VIMPrivacy;
@class VIMUser;
@class VIMConnection;
@class VIMInteraction;

@interface VIMChannel : VIMModelObject

@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, copy) NSString *channelDescription;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection; // Unused for now [AH]
@property (nonatomic, strong) VIMPrivacy *privacy;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) VIMUser *user;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

@end
