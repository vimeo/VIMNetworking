//
//  VIMErrorDomain.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMErrorDomain : NSObject

+ (NSString *)domainName;
+ (NSArray *)errorTypes;

//Methods not to be overriden.
+ (NSString *)errorTypeForDomainName:(NSString *)domainName errorCode:(NSInteger)errorCode;
+ (NSString *)errorDomainForErrorType:(NSString *)errorType;

@end
