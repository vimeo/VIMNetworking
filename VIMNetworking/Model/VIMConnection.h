//
//  VIMConnection.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/16/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
NSString *const VIMConnectionNameUsers;
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
