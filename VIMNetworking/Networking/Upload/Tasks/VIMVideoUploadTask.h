//
//  UploadTask.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"
#import "VIMUploadState.h"

@class VIMVideoMetadata;

typedef void(^UploadStateBlock)(VIMUploadState state);
typedef void(^UploadProgressBlock)(double uploadProgressFraction);
typedef void(^UploadCompletionBlock)(NSString *videoURI, NSError *error);

@interface VIMVideoUploadTask : VIMNetworkTask

// Input
@property (nonatomic, copy) UploadStateBlock uploadStateBlock;
@property (nonatomic, copy) UploadProgressBlock uploadProgressBlock;
@property (nonatomic, copy) UploadCompletionBlock uploadCompletionBlock;

@property (nonatomic, strong) VIMVideoMetadata *videoMetadata;

// Output
@property (nonatomic, assign, readonly) VIMUploadState uploadState;
@property (nonatomic, copy, readonly) NSString *videoURI;

@end
