//
//  VIMPrivacy.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/24/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

extern NSString *VIMPrivacy_Private;
extern NSString *VIMPrivacy_Select;
extern NSString *VIMPrivacy_Public;
extern NSString *VIMPrivacy_VOD;
extern NSString *VIMPrivacy_Following;
extern NSString *VIMPrivacy_Password;

@interface VIMPrivacy : VIMModelObject

@property (nonatomic, copy) NSNumber *canAdd;
@property (nonatomic, copy) NSNumber *canDownload;

@property (nonatomic, copy) NSString *comments;
@property (nonatomic, copy) NSString *embed;
@property (nonatomic, copy) NSString *view;

@end
