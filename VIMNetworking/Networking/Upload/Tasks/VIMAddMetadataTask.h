//
//  MetadataTask.h
//  Hermes
//
//  Created by Hanssen, Alfie on 3/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"

@class VIMVideoMetadata;

@interface VIMAddMetadataTask : VIMNetworkTask

- (instancetype)initWithVideoURI:(NSString *)videoURI metadata:(VIMVideoMetadata *)videoMetadata;

@end
