//
//  VIMClient+Private.h
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/22/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
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

#import "VIMClient.h"

@interface VIMClient (Private)

#pragma mark - APNS

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (id<VIMRequestToken>)registerDeviceForPushNotificationsWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unregisterDeviceForPushNotificationWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)addPushNotificationWithParameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)fetchUserPushNotificationsWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)fetchDevicePushNotificationsWithURI:(NSString *)URI parameters:(NSArray *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)viewPushNotificationWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)removePushNotificationWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

#endif

@end
