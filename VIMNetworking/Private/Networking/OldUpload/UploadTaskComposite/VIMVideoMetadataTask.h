//
//  VIMVideoPrivacyTask.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

typedef void (^VIMVideoMetadataTaskCompletionBlock)(NSError *error);

@interface VIMVideoMetadataTask : VIMTaskOld

@property (nonatomic, copy) NSString *videoURI;
@property (nonatomic, copy) NSString *videoName;
@property (nonatomic, copy) NSString *videoDescription;
@property (nonatomic, copy) NSString *videoPrivacy;

@property (nonatomic, copy) VIMVideoMetadataTaskCompletionBlock completionBlock;

@end