//
//  VIMRequestToken.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/2/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMRequestDescriptor;

@protocol VIMRequestToken <NSObject>

- (VIMRequestDescriptor *)descriptor;

@end
