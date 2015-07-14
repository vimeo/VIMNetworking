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

NSString *const __nonnull VIMConnectionNameActivities;
NSString *const __nonnull VIMConnectionNameAlbums;
NSString *const __nonnull VIMConnectionNameChannels;
NSString *const __nonnull VIMConnectionNameComments;
NSString *const __nonnull VIMConnectionNameCovers;
NSString *const __nonnull VIMConnectionNameCredits;
NSString *const __nonnull VIMConnectionNameFeed;
NSString *const __nonnull VIMConnectionNameFollowers;
NSString *const __nonnull VIMConnectionNameFollowing;
NSString *const __nonnull VIMConnectionNameUsers;
NSString *const __nonnull VIMConnectionNameGroups;
NSString *const __nonnull VIMConnectionNameLikes;
NSString *const __nonnull VIMConnectionNamePictures;
NSString *const __nonnull VIMConnectionNamePortfolios;
NSString *const __nonnull VIMConnectionNameShared;
NSString *const __nonnull VIMConnectionNameVideos;
NSString *const __nonnull VIMConnectionNameWatchlater;
NSString *const __nonnull VIMConnectionNameViolations;

@interface VIMConnection : VIMModelObject

@property (nonatomic, copy, nullable) NSString *uri;
@property (nonatomic, strong, nullable) NSNumber *total;
@property (nonatomic, strong, nullable) NSArray *options;

- (BOOL)canGet;
- (BOOL)canPost;

@end
