//
//  SMKAPIClient.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/6/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMAPIClient.h"

@interface VIMAPIClient (Private)

#pragma mark - Authentication

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock;

- (NSOperation *)joinWithDisplayName:(NSString *)username email:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock;

- (NSOperation *)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMBooleanCompletionBlock)completionBlock;

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock;

- (id<VIMRequestToken>)resetPasswordWithEmail:(NSString *)email completionBlock:(VIMErrorCompletionBlock)completionBlock;

#pragma mark - Utilities

- (id<VIMRequestToken>)logErrorWithParameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - APNS

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (id<VIMRequestToken>)registerDeviceForPushNotificationsWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unregisterDeviceForPushNotificationWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)addPushNotificationWithParameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)fetchUserPushNotificationsWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)fetchDevicePushNotificationsWithURI:(NSString *)URI parameters:(NSArray *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)viewPushNotificationWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)removePushNotificationWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

#endif

@end
