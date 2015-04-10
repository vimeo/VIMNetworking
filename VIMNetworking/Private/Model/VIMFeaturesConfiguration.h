//
//  VIMFeaturesConfiguration.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/13/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMFeaturesConfiguration : VIMModelObject

@property (nonatomic, assign, readonly) BOOL autouploadEnabled;
@property (nonatomic, assign, readonly) BOOL iapEnabled;
@property (nonatomic, assign, readonly) BOOL comScoreEnabled;
@property (nonatomic, assign, readonly) BOOL playTrackingEnabled;
@property (nonatomic, strong, readonly) NSString *chromecastReceiverAppID;

@end
