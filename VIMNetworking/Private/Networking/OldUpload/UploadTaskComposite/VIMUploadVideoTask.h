//
//  VIMUploadVideoTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

@class VIMUploadRecord;

typedef void (^VIMUploadVideoTaskCompletionBlock)(NSError *error);
typedef void (^VIMUploadVideoTaskProgressBlock)(double fractionComplete);

@interface VIMUploadVideoTask : VIMTaskOld

@property (nonatomic, strong) VIMUploadRecord *uploadRecord;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL isExtensionUpload;

@property (nonatomic, copy) VIMUploadVideoTaskCompletionBlock completionBlock;
@property (nonatomic, copy) VIMUploadVideoTaskProgressBlock progressBlock;

@end