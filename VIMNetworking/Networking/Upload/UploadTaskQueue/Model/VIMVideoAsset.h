//
//  VideoAsset.h
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

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "VIMUploadState.h"

@class VIMVideoMetadata;

typedef void(^FileSizeCompletionBlock)(CGFloat fileSize, NSError *error);
typedef void(^ImageCompletionBlock)(UIImage *image, NSError *error);

@interface VIMVideoAsset : NSObject

@property (nonatomic, strong, readonly) NSString *identifier;

@property (nonatomic, strong, readonly) PHAsset *phAsset;
@property (nonatomic, strong, readonly) AVURLAsset *URLAsset;
@property (nonatomic, assign, readonly) BOOL canUploadFromSource;

@property (nonatomic, strong) VIMVideoMetadata *metadata;

@property (nonatomic, assign) VIMUploadState uploadState;
@property (nonatomic, assign) double uploadProgressFraction;

@property (nonatomic, strong) NSString *videoURI;
@property (nonatomic, strong) NSError *error;

- (instancetype)initWithPHAsset:(PHAsset *)phAsset;
- (instancetype)initWithURLAsset:(AVURLAsset *)URLAsset canUploadFromSource:(BOOL)canUploadFromSource;

- (void)requestAVAssetWithCompletionBlock:(void (^)(AVAsset *asset, NSError *error))completionBlock;

- (NSTimeInterval)duration;

- (int32_t)fileSizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock;
- (int32_t)imageWithSize:(CGSize)size completionBlock:(ImageCompletionBlock)completionBlock;

@end
