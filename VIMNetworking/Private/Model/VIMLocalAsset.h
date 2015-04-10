//
//  VIMLocalAsset.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

@class PHAsset;
@class AVAsset;
@class AVAssetExportSession;
@class VIMVideoFile;

@interface VIMLocalAsset : NSObject <NSSecureCoding>

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong, readonly) VIMVideoFile *videoFile;
@property (nonatomic, strong, readonly) PHAsset *phAsset;
@property (nonatomic, copy, readonly) NSString *phLocalIdentifier;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithVideoFile:(VIMVideoFile *)videoFile;
- (instancetype)initWithVideoFile:(VIMVideoFile *)videoFile localFileURL:(NSURL *)URL;
- (instancetype)initWithLocalIdentifier:(NSString *)phLocalIdentifier;

- (void)requestFileSizeWithCompletionBlock:(void (^)(unsigned long long fileSize, NSError *error))completionBlock;
- (void)requestAVAssetWithCompletionBlock:(void (^)(AVAsset *asset, NSError *error))completionBlock;
- (void)requestExportSessionWithPreset:(NSString *)exportPreset completionBlock:(void (^)(AVAssetExportSession *exportSession, NSError *error))completionBlock;

@end
