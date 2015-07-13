//
//  VideoAsset.m
//  VimeoUploader
//
//  Created by Alfred Hanssen on 12/25/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "VIMVideoAsset.h"
#import "AVAsset+Filesize.h"
#import "PHAsset+Filesize.h"

#import <AVFoundation/AVFoundation.h>

@interface VIMVideoAsset () <NSCoding>

@property (nonatomic, strong, readwrite) NSString *identifier;

@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, strong, readwrite) AVURLAsset *URLAsset;
@property (nonatomic, assign, readwrite) BOOL canUploadFromSource;

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

- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset canUploadFromSource:(BOOL)canUploadFromSource
{
    self = [super init];
    if (self)
    {
        _URLAsset = URLAsset;
        _identifier = [URLAsset.URL absoluteString];
        _canUploadFromSource = canUploadFromSource;
    }
    
    return self;
}

- (void)requestAVAssetWithCompletionBlock:(void (^)(AVAsset *asset, NSError *error))completionBlock
{
    if (self.URLAsset)
    {
        if (completionBlock)
        {
            completionBlock(self.URLAsset, nil);
        }
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if (self.phAsset)
    {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.phAsset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            
            NSError *error = [info objectForKey:PHImageErrorKey];
            
            if (completionBlock)
            {
                completionBlock(asset, error);
            }
        }];
    }
#endif
    else
    {
        if (completionBlock)
        {
            completionBlock(nil, nil);
        }
    }
}

- (NSTimeInterval)duration
{
    if (self.phAsset)
    {
        return self.phAsset.duration;
    }
    else if (self.URLAsset)
    {
        return CMTimeGetSeconds(self.URLAsset.duration);
    }
    
    return 0.0f;
}

- (int32_t)fileSizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock
{
    if (self.phAsset)
    {
        return [self.phAsset calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {

            if (completionBlock)
            {
                fileSize = fileSize / (1024.0 * 1024.0);
                completionBlock(fileSize, error);
            }

        }];
    }
    else if (self.URLAsset)
    {
        [self.URLAsset calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {
            
            if (completionBlock)
            {
                fileSize = fileSize / (1024.0 * 1024.0);
                completionBlock(fileSize, error);
            }

        }];
    }
    
    return 0; // No need to return a cancellation handler for non PH requests [AH]
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
           
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:self.URLAsset];
            generator.appliesPreferredTrackTransform = YES;
            generator.maximumSize = size;
            
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
    
    return 0; // TODO: we need to return something that allows calling contexts to cancel the request [AH]
}

- (BOOL)isUploading
{
    return (self.uploadState != VIMUploadState_None && ![self didFinishUploading]);
}

- (BOOL)didFinishUploading
{
    return (self.uploadState == VIMUploadState_Failed || self.uploadState == VIMUploadState_Succeeded);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.identifier = [coder decodeObjectForKey:NSStringFromSelector(@selector(identifier))];
        self.metadata = [coder decodeObjectForKey:NSStringFromSelector(@selector(metadata))];
        self.uploadState = [coder decodeIntegerForKey:NSStringFromSelector(@selector(uploadState))];
        self.videoURI = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoURI))];
        self.error = [coder decodeObjectForKey:NSStringFromSelector(@selector(error))];
        self.canUploadFromSource = [coder decodeBoolForKey:NSStringFromSelector(@selector(canUploadFromSource))];
        
        NSString *assetLocalIdentifier = [coder decodeObjectForKey:@"assetLocalIdentifier"];
        if (assetLocalIdentifier)
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:options];
            self.phAsset = [result firstObject];
            
            NSAssert(self.phAsset, @"Must be able to unarchive PHAsset");
        }
        
        NSURL *URL = [coder decodeObjectForKey:@"URL"];
        if (URL)
        {
            self.URLAsset = [AVURLAsset assetWithURL:URL];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.identifier forKey:NSStringFromSelector(@selector(identifier))];
    [coder encodeObject:self.metadata forKey:NSStringFromSelector(@selector(metadata))];
    [coder encodeInteger:self.uploadState forKey:NSStringFromSelector(@selector(uploadState))];
    [coder encodeObject:self.videoURI forKey:NSStringFromSelector(@selector(videoURI))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
    [coder encodeBool:self.canUploadFromSource forKey:NSStringFromSelector(@selector(canUploadFromSource))];
    
    if (self.phAsset)
    {
        [coder encodeObject:self.phAsset.localIdentifier forKey:@"assetLocalIdentifier"];
    }
    else if (self.URLAsset)
    {
        [coder encodeObject:self.URLAsset.URL forKey:@"URL"];
    }
}

@end
