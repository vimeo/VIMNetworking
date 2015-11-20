//
//  VIMClient.h
//  VIMNetworking
//
//  Created by Alfred Hanssen on 6/21/15.
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

#import <Foundation/Foundation.h>
#import "VIMRequestOperationManager.h"

@protocol VIMRequestToken;

@interface VIMClient : VIMRequestOperationManager

- (nullable instancetype)initWithDefaultBaseURL;

#pragma mark - Utilities

- (nullable id<VIMRequestToken>)resetPasswordWithEmail:(nonnull NSString *)email completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Users

- (nullable id<VIMRequestToken>)userWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)usersWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)updateUserWithURI:(nonnull NSString *)URI name:(nullable NSString *)name location:(nullable NSString *)location bio:(nullable NSString *)bio completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)followUserWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)unfollowUserWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)toggleFollowUserWithURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)toggleFollowURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Pictures

- (nullable id<VIMRequestToken>)createPictureResourceForUserWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)deletePictureResourceWithURI:(nonnull NSString *)URI completionBlock:(nullable VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)activatePictureResourceWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Videos

- (nullable id<VIMRequestToken>)videoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)videosWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)updateVideoWithURI:(nonnull NSString *)URI title:(nullable NSString *)title description:(nullable NSString *)description privacy:(nullable NSString *)privacy completionHandler:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)likeVideoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)unlikeVideoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)toggleLikeVideoWithURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)watchLaterVideoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)unwatchLaterVideoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)toggleWatchLaterVideoWithURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)deleteVideoWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)shareVideoWithURI:(nonnull NSString *)URI recipients:(nonnull NSArray *)recipients completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Search

- (nullable id<VIMRequestToken>)searchVideosWithQuery:(nonnull NSString *)query completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)searchVideosWithQuery:(nonnull NSString *)query filter:(nullable NSString *)filter completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Comments

- (nullable id<VIMRequestToken>)postCommentWithURI:(nonnull NSString *)URI text:(nonnull NSString *)text completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)postReplyWithURI:(nonnull NSString *)URI text:(nonnull NSString *)text completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

- (nullable id<VIMRequestToken>)commentsWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock;

#pragma mark - Logout

- (nullable id<VIMRequestToken>)logoutWithCompletionBlock:(nullable VIMRequestCompletionBlock)completionBlock;

@end
