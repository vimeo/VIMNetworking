//
//  VideoAsset.h
//  VimeoUploader
//
//  Created by Alfred Hanssen on 12/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "VIMUploadState.h"

typedef void(^FileSizeCompletionBlock)(CGFloat fileSize, NSError *error);
typedef void(^ImageCompletionBlock)(UIImage *image, NSError *error);

@interface VIMVideoAsset : NSObject

@property (nonatomic, strong, readonly) NSString *identifier;

@property (nonatomic, strong, readonly) PHAsset *phAsset;
@property (nonatomic, strong, readonly) AVURLAsset *URLAsset;

@property (nonatomic, assign) VIMUploadState uploadState;
@property (nonatomic, assign) double uploadProgressFraction;

@property (nonatomic, strong) NSString *videoURI;
@property (nonatomic, strong) NSError *error;

- (instancetype)initWithPHAsset:(PHAsset *)phAsset;
- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset;

- (int32_t)fileSizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock;
- (int32_t)imageWithSize:(CGSize)size completionBlock:(ImageCompletionBlock)completionBlock;

@end
