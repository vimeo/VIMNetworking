//
//  VIMTaskOperation.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 12/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMTaskOld;

@interface VIMTaskOperation : NSOperation

@property (nonatomic, strong, readonly) VIMTaskOld *task;

- (instancetype)initWithTask:(VIMTaskOld *)task;

@end
