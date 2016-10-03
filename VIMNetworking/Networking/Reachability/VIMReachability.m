//
//  VIMReachability.m
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

#import "VIMReachability.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

//NSString * const VIMReachabilityStatusChangeOfflineNotification = @"VIMReachabilityStatusChangeOfflineNotification";
//NSString * const VIMReachabilityStatusChangeOnlineNotification = @"VIMReachabilityStatusChangeOnlineNotification";
//NSString * const VIMReachabilityStatusChangeWasOfflineInfoKey = @"VIMReachabilityStatusChangeWasOfflineInfoKey";

@interface VIMReachability ()

//@property (nonatomic, assign) BOOL wasOffline;

@end

@implementation VIMReachability

//+ (VIMReachability *)sharedInstance
//{
//    static dispatch_once_t pred;
//    static VIMReachability *sharedInstance = nil;
//    
//    dispatch_once(&pred, ^{
//        sharedInstance = [[VIMReachability alloc] init];
//    });
//    
//    return sharedInstance;
//}
//
//- (instancetype)init
//{
//    self = [super init];
//    if (self)
//    {
//        _wasOffline = NO;
//        
//        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
//        
//        __weak typeof(self) weakSelf = self;
//        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
//            if (status != AFNetworkReachabilityStatusNotReachable)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:VIMReachabilityStatusChangeOnlineNotification object:nil userInfo:@{ VIMReachabilityStatusChangeWasOfflineInfoKey: @(weakSelf.wasOffline) }];
//                });
//                
//                weakSelf.wasOffline = NO;
//            }
//            else
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:VIMReachabilityStatusChangeOfflineNotification object:nil userInfo:@{ VIMReachabilityStatusChangeWasOfflineInfoKey: @(weakSelf.wasOffline) }];
//                });
//                
//                weakSelf.wasOffline = YES;
//            }
//        }];
//    }
//    
//    return self;
//}
//
//#pragma mark - Public API
//
//- (BOOL)isNetworkReachable
//{
//    return [[AFNetworkReachabilityManager sharedManager] isReachable];
//}
//
//- (BOOL)isOn3G
//{
//    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN];
//}
//
//- (BOOL)isOnWiFi
//{
//    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
//}

@end
