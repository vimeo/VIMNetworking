//
//  VIMVideoFairPlayFile.h
//  Vimeo
//
//  Created by King, Gavin on 7/13/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VIMVideoPlayFile.h"

@interface VIMVideoFairPlayFile : VIMVideoHLSFile

@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *certificateLink;
@property (nonatomic, copy, nullable) NSString *licenseLink;

@end