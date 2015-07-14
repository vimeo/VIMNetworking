//
//  PHAsset+Filesize.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/14/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "PHAsset+Filesize.h"
#import "AVAsset+Filesize.h"

@implementation PHAsset (Filesize)

- (CGFloat)calculateFilesize
{
    __block CGFloat size = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    [self calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {
       
        size = fileSize;
        
        dispatch_group_leave(group);
        
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return size;
}

- (int32_t)calculateFilesizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock
{
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat; // TODO: How does this impact things? [AH]
    options.networkAccessAllowed = YES; // TODO: is this a problem? [AH]

    return [[PHImageManager defaultManager] requestAVAssetForVideo:self options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        
        [asset calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {
            
            if (completionBlock)
            {
                NSError *error = info[PHImageErrorKey];
                completionBlock(fileSize, error);
            }

        }];
        
    }];
}

@end
