//
//  VIMCompleteUploadTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

typedef void (^VIMCompleteUploadTaskCompletionBlock)(NSString *videoURI, NSError *error);

@interface VIMCompleteUploadTask : VIMTaskOld

@property (nonatomic, copy) NSString *completeURI;
@property (nonatomic, copy, readonly) NSString *videoURI;

@property (nonatomic, copy) VIMCompleteUploadTaskCompletionBlock completionBlock;

@end