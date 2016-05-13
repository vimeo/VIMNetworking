//
//  VIMVIdeoProgressiveFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoProgressiveFile.h"

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

@end
