//
//  AVAsset+Filesize.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/16/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAsset.h>

typedef void(^FileSizeCompletionBlock)(CGFloat fileSize, NSError *error);

@interface AVAsset (Filesize)

- (CGFloat)calculateFilesize; // Synchronous

- (void)calculateFilesizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock;

@end
