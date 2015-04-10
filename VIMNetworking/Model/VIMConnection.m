//
//  VIMConnection.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMConnection.h"

// Connection names

NSString *const VIMConnectionNameActivities = @"activities";
NSString *const VIMConnectionNameAlbums = @"albums";
NSString *const VIMConnectionNameChannels = @"channels";
NSString *const VIMConnectionNameComments = @"comments";
NSString *const VIMConnectionNameCovers = @"covers";
NSString *const VIMConnectionNameCredits = @"credits";
NSString *const VIMConnectionNameFeed = @"feed";
NSString *const VIMConnectionNameFollowers = @"followers";
NSString *const VIMConnectionNameFollowing = @"following";
NSString *const VIMConnectionNameGroups = @"groups";
NSString *const VIMConnectionNameLikes = @"likes";
NSString *const VIMConnectionNamePictures = @"pictures";
NSString *const VIMConnectionNamePortfolios = @"portfolios";
NSString *const VIMConnectionNameShared = @"shared";
NSString *const VIMConnectionNameVideos = @"videos";
NSString *const VIMConnectionNameWatchlater = @"watchlater";
NSString *const VIMConnectionNameViolations = @"violations";

@implementation VIMConnection

- (BOOL)canGet
{
    return (self.options && [self.options containsObject:@"GET"]);
}

- (BOOL)canPost
{
    return (self.options && [self.options containsObject:@"POST"]);
}

@end
