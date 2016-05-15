//
//  VIMVideoProgressiveFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoProgressiveFile.h"
@import AVFoundation;

@implementation VIMVideoProgressiveFile

#pragma mark - VIMMappable override

- (void)didFinishMapping
{
    [super didFinishMapping];
    
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
}

#pragma mark - VIMVideoPlayFile override

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

- (NSString *)qualityString
{
    // TODO: We no longer receive quality from API, but have been logging quality of progressive files in analytics.
    // The criteria below matches what we are seeing from API in legacy VIMVideoFile BUT not without error.
    // Based on my testing, a low frequency of errors (e.g. 1-2 files per 4-6 pages of results) suggests this is incorrect, and/or API is using something other than size to determine quality, or those videos are not marked correctly.
    // Need to determine if we should (1) ask API for this or (2) log our quality as simply "hls" or "progressive". For option (2), we would simply return "progressive" here. [NL] 05/15/16
    
    NSNumber *mobileMin = @(360);
    NSNumber *mobileMax = @(640);
    
    NSNumber *standardDefMin = @(720);
    NSNumber *standardDefMax = @(961);
    
    if (MIN(self.width, self.height) < mobileMin &&
        MAX(self.width, self.height) < mobileMax)
    {
        return @"mobile";
    }
    else if (MIN(self.width, self.height) < standardDefMin &&
             MAX(self.width, self.height) < standardDefMax)
    {
        return @"sd";
    }
    
    return @"hd";
}

@end
