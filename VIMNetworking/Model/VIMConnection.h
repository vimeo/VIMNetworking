//
//  VIMConnection.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

// Connection names

NSString *const VIMConnectionNameActivities;
NSString *const VIMConnectionNameAlbums;
NSString *const VIMConnectionNameChannels;
NSString *const VIMConnectionNameComments;
NSString *const VIMConnectionNameCovers;
NSString *const VIMConnectionNameCredits;
NSString *const VIMConnectionNameFeed;
NSString *const VIMConnectionNameFollowers;
NSString *const VIMConnectionNameFollowing;
NSString *const VIMConnectionNameGroups;
NSString *const VIMConnectionNameLikes;
NSString *const VIMConnectionNamePictures;
NSString *const VIMConnectionNamePortfolios;
NSString *const VIMConnectionNameShared;
NSString *const VIMConnectionNameVideos;
NSString *const VIMConnectionNameWatchlater;
NSString *const VIMConnectionNameViolations;

@interface VIMConnection : VIMModelObject

@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSNumber *total;
@property (nonatomic, strong) NSArray *options;

- (BOOL)canGet;
- (BOOL)canPost;

@end
