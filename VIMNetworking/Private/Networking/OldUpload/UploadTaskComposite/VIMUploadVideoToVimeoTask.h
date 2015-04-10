//
//  VIMUploadVideoToVimeoTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

@class VIMLocalAsset;

typedef void (^VIMUploadVideoToVimeoProgressBlock)(double fractionCompleted);
typedef void (^VIMUploadVideoToVimeoCompletionBlock)(NSString *videoURI, BOOL isCanceled, NSError *error);

@interface VIMUploadVideoToVimeoTask : VIMTaskOld

@property (nonatomic, strong) VIMLocalAsset *localAsset;
@property (nonatomic, copy) NSString *videoObjectID;
@property (nonatomic, copy) NSString *videoName;
@property (nonatomic, copy) NSString *videoDescription;
@property (nonatomic, copy) NSString *videoPrivacy;
@property (nonatomic, copy) NSString *videoQualityExportPreset;

@property (nonatomic, assign) BOOL isExtensionUpload;

@property (nonatomic, copy, readonly) NSString *videoURI;

@property (nonatomic, copy) VIMUploadVideoToVimeoProgressBlock progressBlock;
@property (nonatomic, copy) VIMUploadVideoToVimeoCompletionBlock completionBlock;

@end