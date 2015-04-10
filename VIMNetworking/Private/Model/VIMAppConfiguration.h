//
//  VIMAppConfiguration.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 10/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMFacebookConfiguration;
@class VIMFeaturesConfiguration;
@class VIMAPIConfiguration;

@interface VIMAppConfiguration : VIMModelObject

@property (nonatomic, strong, readonly) VIMFacebookConfiguration *facebookConfiguration;
@property (nonatomic, strong, readonly) VIMFeaturesConfiguration *featuresConfiguration;
@property (nonatomic, strong, readonly) VIMAPIConfiguration *APIConfiguration;

@property (nonatomic, strong, readonly) NSString *keyValueHash;

@end
