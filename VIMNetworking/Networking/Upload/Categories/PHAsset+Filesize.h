//
//  PHAsset+Filesize.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/14/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void(^FileSizeCompletionBlock)(CGFloat fileSize, NSError * __nullable error);

@interface PHAsset (Filesize)

- (CGFloat)calculateFilesize; // Synchronous

- (int32_t)calculateFilesizeWithCompletionBlock:(nonnull FileSizeCompletionBlock)completionBlock;

@end
