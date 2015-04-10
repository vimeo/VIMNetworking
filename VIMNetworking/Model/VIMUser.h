//
//  VIMUser.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/4/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VIMModelObject.h"

@class VIMConnection;
@class VIMInteraction;
@class VIMPictureCollection;

typedef NS_ENUM(NSInteger, VIMUserAccountType)
{
    VIMUserAccountTypeBasic = 0,
    VIMUserAccountTypePro,
    VIMUserAccountTypePlus,
    VIMUserAccountTypeStaff
};

@interface VIMUser : VIMModelObject

@property (nonatomic, assign, readonly) VIMUserAccountType accountType;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *contentFilter;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;
@property (nonatomic, strong) id stats;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSArray *websites;
@property (nonatomic, strong) NSDictionary *uploadQuota;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

- (BOOL)hasCopyrightMatch;
- (BOOL)isFollowing;

@end
