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

#pragma mark - Utilities

- (id<VIMRequestToken>)resetPasswordWithEmail:(NSString *)email completionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Users

- (id<VIMRequestToken>)userWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)usersWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)updateUserWithURI:(NSString *)URI username:(NSString *)username location:(NSString *)location completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)followUserWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unfollowUserWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleFollowUserWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Videos

- (id<VIMRequestToken>)videoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)videosWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)updateVideoWithURI:(NSString *)URI title:(NSString *)title description:(NSString *)description privacy:(NSString *)privacy completionHandler:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)likeVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unlikeVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleLikeVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)watchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)unwatchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)toggleWatchLaterVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)deleteVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)shareVideoWithURI:(NSString *)URI recipients:(NSArray *)recipients completionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Search

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query filter:(NSString *)filter completionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Comments

- (id<VIMRequestToken>)postCommentWithURI:(NSString *)URI text:(NSString *)text completionBlock:(VIMRequestCompletionBlock)completionBlock;

- (id<VIMRequestToken>)commentsWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock;

#pragma mark - Logout

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock;

@end
