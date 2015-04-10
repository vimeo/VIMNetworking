//
//  VIMReachability.h
//  VIMLibrary
//
//  Created by Jason Hawkins on 3/25/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

extern NSString * const VIMReachabilityStatusChangeOfflineNotification;
extern NSString * const VIMReachabilityStatusChangeOnlineNotification;
extern NSString * const VIMReachabilityStatusChangeWasOfflineInfoKey;

@interface VIMReachability : NSObject

+ (VIMReachability *)sharedInstance;

@property (nonatomic, assign, readonly) BOOL isNetworkReachable;
@property (nonatomic, assign, readonly) BOOL isOn3G;
@property (nonatomic, assign, readonly) BOOL isOnWiFi;

@end
