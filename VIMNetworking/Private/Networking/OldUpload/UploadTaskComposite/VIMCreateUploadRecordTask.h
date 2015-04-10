//
//  VIMCreateUploadRecordTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

@class VIMUploadRecord;

typedef void (^CreateUploadRecordCompletionBlock)(NSError* error);

@interface VIMCreateUploadRecordTask : VIMTaskOld

@property (nonatomic, strong, readonly) VIMUploadRecord *uploadRecord;

@property (nonatomic, copy) CreateUploadRecordCompletionBlock completionBlock;

@end