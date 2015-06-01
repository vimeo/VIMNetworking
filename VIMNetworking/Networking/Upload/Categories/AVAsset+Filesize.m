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

- (CGFloat)calculateFilesizeInMB
{
    CGFloat rawSize = [self calculateFilesize];
    
    return rawSize / (1024.0 * 1024.0);
}

- (CGFloat)calculateFilesize
{
    CGFloat rawSize = 0;
    
    if ([self isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset *asset = (AVURLAsset *)self;
        
        NSNumber *size = nil;
        NSError *error = nil;

        BOOL success = [asset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
        
        if (success)
        {
            rawSize = [size floatValue];
        }
        else
        {
            NSLog(@"Error calculating filesize of AVAsset: %@", error);
            
            float estimatedSize = 0.0;
            
            NSArray *tracks = [asset tracks];
            for (AVAssetTrack * track in tracks)
            {
                float rate = [track estimatedDataRate] / 8.0f; // convert bits per second to bytes per second
                float seconds = CMTimeGetSeconds([track timeRange].duration);
                estimatedSize += seconds * rate;
            }
            
            rawSize = estimatedSize;
        }
    }
    else if ([self isKindOfClass:[AVComposition class]])
    {
        // TODO: calculate filesize of AVComposition
    }
    
    return rawSize;
}

@end
