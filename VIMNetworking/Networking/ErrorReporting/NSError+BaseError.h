//
//  NSError+BaseError.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/14/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>

// TODO: morph this into a proper VIMError class [AH] 5/15/15

extern NSString * const __nonnull VimeoErrorCodeHeaderKey;
extern NSString * const __nonnull VimeoErrorCodeKey;
extern NSString * const __nonnull VimeoErrorDomainKey;

extern NSString * const __nonnull BaseErrorKey;
extern NSString * const __nonnull AFNetworkingErrorDomain; // TODO: Why is this necessary? [AH] 5/15/15
extern NSString * const __nonnull kVimeoServerErrorDomain;

typedef NS_ENUM(NSInteger, VIMErrorCode)
{
    VIMErrorCodeUploadStorageQuotaExceeded = 4101,
    VIMErrorCodeUploadDailyQuotaExceeded = 4102
};

@interface NSError (BaseError)

+ (nullable NSError *)errorFromServerError:(nullable NSError *)error withNewDomain:(nullable NSString *)domain;

+ (nullable NSError *)vimeoErrorFromError:(nullable NSError *)error withVimeoDomain:(nullable NSString *)vimeoDomain vimeoErrorCode:(NSInteger)vimeoErrorCode;

@end
