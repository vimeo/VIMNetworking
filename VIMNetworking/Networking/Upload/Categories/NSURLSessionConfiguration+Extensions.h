//
//  NSURLSessionConfiguration+Extensions.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/9/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSessionConfiguration (Extensions)

+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithID:(NSString *)sessionID sharedContainerID:(NSString *)sharedContainerID;

@end
