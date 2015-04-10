//
//  VideoMetadata.h
//  Hermes
//
//  Created by Hanssen, Alfie on 3/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VIMPrivacyValue.h"

@interface VIMVideoMetadata : NSObject

@property (nonatomic, strong) NSString *videoTitle;
@property (nonatomic, strong) NSString *videoDescription;
@property (nonatomic, strong) NSString *videoPrivacy;
@property (nonatomic, strong) NSArray *tags;

@end
