//
//  VIMLocalAsset.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMLocalAsset.h"

#import <AssetsLibrary/AssetsLibrary.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
#import <Photos/Photos.h>
#endif

#import "VIMVideoFile.h"

@interface VIMLocalAsset ()

@property (nonatomic, strong, readwrite) VIMVideoFile *videoFile;
@property (nonatomic, strong, readwrite) PHAsset *phAsset;
@property (nonatomic, copy, readwrite) NSString *phLocalIdentifier;

@end

@implementation VIMLocalAsset

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if(self)
    {
        self.url = url;
    }
    
    return self;
}

- (instancetype)initWithVideoFile:(VIMVideoFile *)videoFile localFileURL:(NSURL *)URL
{
    self = [super init];
    if(self)
    {
        self.videoFile = videoFile;
        self.url = URL;
    }
    
    return self;
}

- (instancetype)initWithVideoFile:(VIMVideoFile *)videoFile
{
    self = [super init];
    if(self)
    {
        self.videoFile = videoFile;
        self.url = [NSURL URLWithString:videoFile.link];
    }
    
    return self;
}

- (instancetype)initWithLocalIdentifier:(NSString *)phLocalIdentifier
{
    self = [super init];
    if(self)
    {
        self.phLocalIdentifier = phLocalIdentifier;
    }
    
    return self;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.phLocalIdentifier = [aDecoder decodeObjectForKey:@"phLocalIdentifier"];
        self.videoFile = [aDecoder decodeObjectForKey:@"videoFile"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeObject:self.phLocalIdentifier forKey:@"phLocalIdentifier"];
    [aCoder encodeObject:self.videoFile forKey:@"videoFile"];
}

#pragma mark - methods

- (void)requestFileSizeWithCompletionBlock:(void (^)(unsigned long long fileSize, NSError *error))completionBlock;
{
    if (self.videoFile.size)
    {
        if (completionBlock)
        {
            completionBlock(self.videoFile.size.unsignedLongLongValue, nil);
        }
    }
    else if(self.url)
    {
        if (completionBlock)
        {
            unsigned long long fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[self.url path] error:NULL] objectForKey:NSFileSize] unsignedLongLongValue];
            completionBlock(fileSize, nil);
        }
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if(self.phAsset)
    {
        [self requestAVAssetWithCompletionBlock:^(AVAsset *asset, NSError *error)
         {
             if (completionBlock)
             {
                 //This is the approximate file size which is the best we can do with PHAssets.
                 unsigned long long fileSize = 0.0f;
                 if (asset != nil)
                 {
                     if ([asset isKindOfClass:[AVURLAsset class]])
                     {
                         AVURLAsset *urlAsset = (AVURLAsset *)asset;
                         NSNumber *size;
                         [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];
                         fileSize = [size unsignedLongLongValue];
                     }
                     else
                     {
                         NSArray *tracks = [asset tracks];
                         for (AVAssetTrack *track in tracks)
                         {
                             float rate = ([track estimatedDataRate] / 8); // convert bits per second to bytes per second
                             float seconds = CMTimeGetSeconds([track timeRange].duration);
                             fileSize += seconds * rate;
                         }
                     }
                 }
                 completionBlock(fileSize, error);
             }
         }];
    }
#endif
}

- (void)requestAVAssetWithCompletionBlock:(void (^)(AVAsset *asset, NSError *error))completionBlock
{
    if(self.url)
    {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.url options:nil];
        
        completionBlock(asset, nil);
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if(self.phAsset)
    {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.phAsset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {

            NSError *error = [info objectForKey:PHImageErrorKey];
            completionBlock(asset, error);
        }];
    }
#endif
    else
    {
        completionBlock(nil, nil);
    }
}

- (void)requestExportSessionWithPreset:(NSString *)exportPreset completionBlock:(void (^)(AVAssetExportSession *exportSession, NSError *error))completionBlock
{
    if(self.url)
    {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.url options:nil];
        AVAssetExportSession *exportSession=[AVAssetExportSession exportSessionWithAsset:asset presetName:exportPreset];
        completionBlock(exportSession, nil);
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if(self.phAsset)
    {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestExportSessionForVideo:self.phAsset options:options exportPreset:exportPreset resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info) {
            
            NSError *error = [info objectForKey:PHImageErrorKey];
            completionBlock(exportSession, error);
        }];
    }
#endif
    else
    {
        completionBlock(nil, nil);
    }
}

- (PHAsset *)phAsset
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if([PHAsset class] && self.phLocalIdentifier)
    {
        if(_phAsset == nil)
        {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.phLocalIdentifier] options:nil];
            _phAsset = [fetchResult firstObject];
        }

        return _phAsset;
    }
#endif
    
    return nil;
}

@end
