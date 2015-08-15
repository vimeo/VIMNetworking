//
//  VIMTaskQueueArchiver.h
//  Pods
//
//  Created by Alfred Hanssen on 8/14/15.
//
//

#import <Foundation/Foundation.h>
#import "VIMTaskQueue.h"

@interface VIMTaskQueueArchiver : NSObject <VIMTaskQueueArchiverProtocol>

- (nullable instancetype)initWithSharedContainerID:(nonnull NSString *)containerID;

@end
