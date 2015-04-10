//
//  VIMVideoFile.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/13/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMVideoFile.h"

#import "VIMVideoLog.h"
#import <AVFoundation/AVFoundation.h>

NSString *const VIMVideoFileQualityHLS = @"hls";
NSString *const VIMVideoFileQualityHD = @"hd";
NSString *const VIMVideoFileQualitySD = @"sd";
NSString *const VIMVideoFileQualityMobile = @"mobile";

@interface VIMVideoFile ()

@property (nonatomic, copy) NSString *expires;

@end

@implementation VIMVideoFile

#pragma mark - VIMMappable

- (Class)getClassForObjectKey:(NSString *)key
{
    if( [key isEqualToString:@"log"] )
        return [VIMVideoLog class];
    
    return nil;
}

- (void)didFinishMapping
{
    if (![self.width isKindOfClass:[NSNumber class]])
    {
        self.width = @(0);
    }

    if (![self.height isKindOfClass:[NSNumber class]])
    {
        self.height = @(0);
    }

    if (![self.size isKindOfClass:[NSNumber class]])
    {
        self.size = @(0);
    }

    if ([self.expires isKindOfClass:[NSString class]])
    {
        self.expirationDate = [[VIMModelObject dateFormatter] dateFromString:self.expires];
    }
    else
    {
        self.expirationDate = nil;
    }
}

#pragma mark

//    As of Oct 27, 2014:
//    \VideoCodec::CODEC_H264 => 'video/mp4',
//    \VideoCodec::CODEC_VP8 => 'video/webm',
//    \VideoCodec::CODEC_VP6 => 'vp6/x-video'

- (BOOL)isSupportedMimeType
{
    if (self.type == nil)
    {
        return NO;
    }
    
    return [AVURLAsset isPlayableExtendedMIMEType:self.type];
}

- (BOOL)isDownloadable
{
    return [self isSupportedMimeType] && ([self.quality isEqualToString:VIMVideoFileQualityMobile] || [self.quality isEqualToString:VIMVideoFileQualitySD] || [self.quality isEqualToString:VIMVideoFileQualityHD]);
}

- (BOOL)isStreamable
{
    return [self isSupportedMimeType] && ([self.quality isEqualToString:VIMVideoFileQualityMobile] || [self.quality isEqualToString:VIMVideoFileQualitySD] || [self.quality isEqualToString:VIMVideoFileQualityHD] || [self.quality isEqualToString:VIMVideoFileQualityHLS]);
}

@end
