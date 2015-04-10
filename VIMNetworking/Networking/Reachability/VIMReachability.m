//
//  VIMReachability.m
//  VIMLibrary
//
//  Created by Jason Hawkins on 3/25/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMReachability.h"

#import "AFNetworkReachabilityManager.h"

NSString * const VIMReachabilityStatusChangeOfflineNotification = @"VIMReachabilityStatusChangeOfflineNotification";
NSString * const VIMReachabilityStatusChangeOnlineNotification = @"VIMReachabilityStatusChangeOnlineNotification";
NSString * const VIMReachabilityStatusChangeWasOfflineInfoKey = @"VIMReachabilityStatusChangeWasOfflineInfoKey";

@interface VIMReachability ()

@property (nonatomic, assign) BOOL wasOffline;

@end

@implementation VIMReachability

+ (VIMReachability *)sharedInstance
{
    static dispatch_once_t pred;
    static VIMReachability *sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[VIMReachability alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _wasOffline = NO;
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        __weak typeof(self) weakSelf = self;
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
        {
            if (status != AFNetworkReachabilityStatusNotReachable)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:VIMReachabilityStatusChangeOnlineNotification object:nil userInfo:@{ VIMReachabilityStatusChangeWasOfflineInfoKey: @(weakSelf.wasOffline) }];
                weakSelf.wasOffline = NO;
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:VIMReachabilityStatusChangeOfflineNotification object:nil userInfo:@{ VIMReachabilityStatusChangeWasOfflineInfoKey: @(weakSelf.wasOffline) }];
                weakSelf.wasOffline = YES;
            }
        }];
    }
    
    return self;
}

#pragma mark - Public API

- (BOOL)isNetworkReachable
{
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

- (BOOL)isOn3G
{
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN];
}

- (BOOL)isOnWiFi
{
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
}

//        [self.timer invalidate];
//        
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:DefaultNotificationDelay target:self selector:@selector(notify) userInfo:nil repeats:NO];

@end
