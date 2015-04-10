//
//  VIMVideo.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/23/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMUser;
@class VIMVideoFile;
@class VIMConnection;
@class VIMPictureCollection;
@class VIMInteraction;
@class VIMPrivacy;
@class VIMAppeal;
@class VIMLocalAsset;
@class VIMVideoLog;

@interface VIMVideo : VIMModelObject

@property (nonatomic, copy) NSArray *contentRating;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, copy) NSString *videoDescription;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, copy) NSString *license;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;
@property (nonatomic, strong) NSDictionary *stats;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) VIMUser *user;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) VIMAppeal *appeal;
@property (nonatomic, strong) VIMPrivacy *privacy;
@property (nonatomic, strong) VIMVideoLog *log;
@property (nonatomic, strong) NSNumber *numPlays;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

// Local Asset
@property (nonatomic, strong) VIMLocalAsset *assetForPlayback;

// Helpers

- (BOOL)canViewInfo;
- (BOOL)canComment;
- (BOOL)canViewComments;
- (BOOL)isVOD;
- (BOOL)isPrivate;
- (BOOL)isAvailable;

@end
