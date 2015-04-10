//
//  VIMUploadManager.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 20/08/2013.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMTaskQueueOld.h"


@interface VIMUploadTaskQueueOld : VIMTaskQueueOld

+ (VIMUploadTaskQueueOld *)sharedInstance;

- (instancetype)initWithName:(NSString *)name useAppGroupCache:(BOOL)useAppGroupCache;

@end
