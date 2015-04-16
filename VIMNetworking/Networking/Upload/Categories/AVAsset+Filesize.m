//
//  AVAsset+Filesize.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/16/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "AVAsset+Filesize.h"
#import <AVFoundation/AVComposition.h>
#import <AVFoundation/AVCompositionTrack.h>
#import <AVFoundation/AVCompositionTrackSegment.h>

@implementation AVAsset (Filesize)

- (uint64_t)calculateFilesize
{
    uint64_t rawSize = 0;
    
    NSNumber *size = nil;
    NSError *error = nil;
    
    if ([self isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset *asset = (AVURLAsset *)self;
        
        [asset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
        if (error)
        {
            NSLog(@"Error calculating AVURLAsset filesize: %@", error);
        }
        else
        {
            rawSize = [size unsignedLongLongValue];
        }
    }
    else if ([self isKindOfClass:[AVComposition class]])
    {
        // TODO: calculate filesize of AVComposition
    }
    
    return rawSize;
}

@end
