//
//  VideoAsset.m
//  VimeoUploader
//
//  Created by Alfred Hanssen on 12/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMVideoAsset.h"

#import <AVFoundation/AVFoundation.h>

@interface VIMVideoAsset ()

@property (nonatomic, strong, readwrite) NSString *identifier;

@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, strong, readwrite) AVURLAsset *URLAsset;

@end

@implementation VIMVideoAsset

- (instancetype)initWithPHAsset:(PHAsset *)phAsset
{
    self = [super init];
    if (self)
    {
        _phAsset = phAsset;
        _identifier = phAsset.localIdentifier;
    }
    
    return self;
}

- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset
{
    self = [super init];
    if (self)
    {
        _URLAsset = URLAsset;
        _identifier = [URLAsset.URL absoluteString];
    }
    
    return self;
}

- (int32_t)fileSizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock
{
    if (self.phAsset)
    {
        return [[PHImageManager defaultManager] requestAVAssetForVideo:self.phAsset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            
            CGFloat rawSize = [self fileSizeForAsset:asset];
            
            if (completionBlock)
            {
                NSError *error = info[PHImageErrorKey];
                completionBlock(rawSize, error);
            }
            
        }];
    }
    else if (self.URLAsset)
    {
        CGFloat rawSize = [self fileSizeForAsset:self.URLAsset];
        if (completionBlock)
        {
            completionBlock(rawSize, nil);
        }
    }
    
    return 0;
}

- (int32_t)imageWithSize:(CGSize)size completionBlock:(ImageCompletionBlock)completionBlock
{
    if (self.phAsset)
    {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        return [[PHImageManager defaultManager] requestImageForAsset:self.phAsset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
            
            if (completionBlock)
            {
                NSError *error = info[PHImageErrorKey];
                completionBlock(result, error);
            }
            
        }];
    }
    else if (self.URLAsset)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:self.URLAsset];
            generator.appliesPreferredTrackTransform = YES;
//            generator.maximumSize =
            
            NSError *error = nil;
            CMTime duration = self.URLAsset.duration;
            CMTime time = CMTimeMakeWithSeconds(1, duration.timescale);
            CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:NULL error:&error];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            
            if (completionBlock)
            {
                completionBlock(image, error);
            }

        });
    }
    
    return 0;
}

#pragma mark - Utilities

- (CGFloat)fileSizeForAsset:(AVAsset *)asset
{
    CGFloat rawSize = 0;
    
    if ([asset isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset *URLAsset = (AVURLAsset *)asset;
        NSNumber *size;
        [URLAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        rawSize = [size floatValue] / (1024.0 * 1024.0);
    }

    return rawSize;
}

@end
