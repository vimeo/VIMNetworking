//
//  VIMRemoveFileTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

typedef void (^VIMRemoveFileTaskCompletionBlock)(NSError *error);

@interface VIMRemoveFileTask : VIMTaskOld

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, copy) VIMRemoveFileTaskCompletionBlock completionBlock;

@end