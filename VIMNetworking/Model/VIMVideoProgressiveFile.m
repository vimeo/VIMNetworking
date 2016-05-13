//
//  VIMVIdeoProgressiveFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoProgressiveFile.h"
#import "VIMVideoLog.h"

@interface VIMVideoProgressiveFile ()
@property (nonatomic, copy) NSString *expires;
@end

@implementation VIMVideoProgressiveFile

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"link_expiration_time": @"expires"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"log"])
    {
        return [VIMVideoLog class];
    }
    
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

#pragma mark - VIMVideoFileProtocol

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

- (BOOL)isExpired
{
    if (!self.expirationDate) // This will yield NSOrderedSame (weird), so adding an explicit check here [AH] 9/14/2015
    {
        return NO;
    }
    
    NSComparisonResult result = [[NSDate date] compare:self.expirationDate];
    
    return (result == NSOrderedDescending);
}

@end
