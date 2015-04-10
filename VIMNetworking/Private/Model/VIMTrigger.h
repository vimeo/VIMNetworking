//
//  VIMTrigger.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 10/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMTrigger : VIMModelObject

@property (nonatomic, copy, readonly) NSString *uri;
@property (nonatomic, copy, readonly) NSString *contextType;
@property (nonatomic, copy, readonly) NSString *contextUri;

- (BOOL)isEnabled;

@end
