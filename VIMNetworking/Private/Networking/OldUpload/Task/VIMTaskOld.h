//
//  VIMTask_VIMTask_Private.h
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/26/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VIMTaskStatus)
{
    VIMTaskStatus_Waiting,
    VIMTaskStatus_Progress,
    VIMTaskStatus_Finished,
};

@interface VIMTaskOld : NSObject <NSCoding>

@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSString* taskID;
@property (nonatomic, strong) NSOperation *operation;

@property (nonatomic, assign) VIMTaskStatus status;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL isPaused;

- (void)start;
- (void)cancel;
- (void)pause;
- (void)resume;
- (void)stop;

- (void)prepareForRetry;

@end
