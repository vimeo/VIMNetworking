//
//  NSError+VIMNetworking.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 6/23/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (VIMNetworking)

- (BOOL)isServiceUnavailableError;

- (BOOL)isInvalidTokenError;

- (BOOL)isForbiddenError;

- (BOOL)isUploadQuotaError;
- (BOOL)isUploadQuotaDailyExceededError;
- (BOOL)isUploadQuotaStorageExceededError;

@end
