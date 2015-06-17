//
//  VIMPreference.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/16/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMVideoPreference;

@interface VIMPreference : VIMModelObject

@property (nonatomic, strong) VIMVideoPreference *videos;

@end
