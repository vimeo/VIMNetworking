//
//  VIMUploadRecord.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 12/9/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMUploadRecord : NSObject

@property (nonatomic, copy) NSString *completeURI;
@property (nonatomic, copy) NSString *uploadURISecure;

@end
