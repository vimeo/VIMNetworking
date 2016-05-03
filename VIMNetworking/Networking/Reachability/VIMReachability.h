//
//  VIMReachability.h
//  VIMNetworking
//
//  Created by Jason Hawkins on 3/25/13.
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

extern NSString * const __nonnull VIMReachabilityStatusChangeOfflineNotification;
extern NSString * const __nonnull VIMReachabilityStatusChangeOnlineNotification;
extern NSString * const __nonnull VIMReachabilityStatusChangeWasOfflineInfoKey;

@interface VIMReachability : NSObject

+ (nullable instancetype)sharedInstance;

@property (nonatomic, assign, readonly) BOOL isNetworkReachable;
@property (nonatomic, assign, readonly) BOOL isOn3G;
@property (nonatomic, assign, readonly) BOOL isOnWiFi;

@end
