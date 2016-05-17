//
//  VIMVideoProgressiveFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoProgressiveFile.h"
@import AVFoundation;

@interface VIMVideoProgressiveFile()

@property (nonatomic, copy, nullable) NSString *createdTime;
@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, strong, nullable) NSNumber *width;
@property (nonatomic, strong, nullable) NSNumber *height;

@end

@implementation VIMVideoProgressiveFile

#pragma mark - VIMMappable override

- (NSDictionary *)getObjectMapping
{
    return @{@"type": @"mimeType",
             @"size": @"sizeInBytes"};
}

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
    
    if (![self.sizeInBytes isKindOfClass:[NSNumber class]])
    {
        self.sizeInBytes = @(0);
    }
    
    if (![self.fps isKindOfClass:[NSNumber class]])
    {
        self.fps = @(0);
    }
    
    if ([self.createdTime isKindOfClass:[NSString class]])
    {
        self.creationDate = [[VIMModelObject dateFormatter] dateFromString:self.createdTime];
    }
    
    [self setDimensions];
}

- (void)setDimensions
{
    NSInteger width = self.width.integerValue;
    NSInteger height = self.height.integerValue;
    
    self.dimensions = CGSizeMake(width, height);
}

//    As of Oct 27, 2014:
//    \VideoCodec::CODEC_H264 => 'video/mp4',
//    \VideoCodec::CODEC_VP8 => 'video/webm',
//    \VideoCodec::CODEC_VP6 => 'vp6/x-video'

- (BOOL)isSupportedMimeType
{
    if (self.mimeType == nil)
    {
        return NO;
    }
    
    return [AVURLAsset isPlayableExtendedMIMEType:self.mimeType];
}

@end
