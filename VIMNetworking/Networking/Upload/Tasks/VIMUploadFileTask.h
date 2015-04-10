//
//  UploadFileTask.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"

@interface VIMUploadFileTask : VIMNetworkTask

// Output
@property (nonatomic, strong, readonly) NSProgress *uploadProgress;

- (instancetype)initWithSource:(NSString *)source destination:(NSString *)destination;

@end
