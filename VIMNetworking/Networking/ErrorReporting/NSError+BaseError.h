//
//  NSError+BaseError.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/14/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const BaseErrorKey;
extern NSString * const AFNetworkingErrorDomain;
extern NSString * const kVimeoServerErrorDomain;

@interface NSError (BaseError)

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message;

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code baseError:(NSError *)baseError;

+ (NSError *)errorFromServerError:(NSError *)error withNewDomain:(NSString *)domain;

@end
