//
//  VIMCopyFileToTempTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

@class VIMLocalAsset;

typedef void (^VIMCopyFileToTempTaskCompletionBlock)(NSString *tmpPath, NSError *error);

@interface VIMCopyFileToTempTask : VIMTaskOld

@property (nonatomic, strong) VIMLocalAsset *localAsset;
@property (nonatomic, copy) NSString *tmpPath;
@property (nonatomic, copy) NSString *exportPreset;

@property (nonatomic, copy) VIMCopyFileToTempTaskCompletionBlock completionBlock;

@end