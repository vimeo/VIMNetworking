//
//  VIMVimeoSessionConfiguration.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMSessionConfiguration : NSObject

@property (nonatomic, copy) NSString *clientKey;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *scope;

@property (nonatomic, copy) NSString *backgroundSessionIdentifierApp;
@property (nonatomic, copy) NSString *backgroundSessionIdentifierExtension;
@property (nonatomic, copy) NSString *sharedContainerID;

@property (nonatomic, copy) NSString *APIVersionString;

- (BOOL)isValid;

@end
