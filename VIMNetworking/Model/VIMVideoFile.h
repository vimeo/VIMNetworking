//
//  VIMVideoFile.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/13/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VIMModelObject.h"

@class VIMVideoLog;

extern NSString *const VIMVideoFileQualityHLS;
extern NSString *const VIMVideoFileQualityHD;
extern NSString *const VIMVideoFileQualitySD;
extern NSString *const VIMVideoFileQualityMobile;

@interface VIMVideoFile : VIMModelObject

@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *size;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *quality;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) VIMVideoLog *log;

- (BOOL)isSupportedMimeType;
- (BOOL)isDownloadable;
- (BOOL)isStreamable;

@end
