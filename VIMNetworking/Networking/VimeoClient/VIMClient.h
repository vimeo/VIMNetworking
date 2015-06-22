//
//  VIMClient.h
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/21/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VIMRequestOperationManager.h"

@protocol VIMRequestToken;

@class VIMRequestDescriptor;

@interface VIMClient : VIMRequestOperationManager

#pragma mark - Utilities

- (id<VIMRequestToken>)resetPasswordWithEmail:(NSString *)email completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Users

- (id<VIMRequestToken>)userWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)usersWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)updateUserWithURI:(NSString *)URI username:(NSString *)username location:(NSString *)location completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)followUserWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unfollowUserWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleFollowUserWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Videos

- (id<VIMRequestToken>)videoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)videosWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)updateVideoWithURI:(NSString *)URI title:(NSString *)title description:(NSString *)description privacy:(NSString *)privacy completionHandler:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)likeVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unlikeVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleLikeVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)watchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unwatchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleWatchLaterVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)deleteVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)shareVideoWithURI:(NSString *)URI recipients:(NSArray *)recipients completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Search

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query filter:(NSString *)filter completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Comments

- (id<VIMRequestToken>)postCommentWithURI:(NSString *)URI text:(NSString *)text completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)commentsWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Logout

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock;

@end
