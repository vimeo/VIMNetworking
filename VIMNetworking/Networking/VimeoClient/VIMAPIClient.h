//
//  VIMAPIManager.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/20/14.
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

#import "VIMRequestOperationManager.h"

typedef void (^VIMErrorCompletionBlock)(NSError *error);
typedef void (^VIMBooleanCompletionBlock)(BOOL value, NSError *error);

@interface VIMAPIClient : NSObject

+ (instancetype)sharedClient;

#pragma mark - Authentication

- (NSURL *)codeGrantAuthorizationURL;

- (NSString *)codeGrantRedirectURI;

- (NSOperation *)authenticateWithClientCredentialsGrant:(VIMErrorCompletionBlock)completionBlock;

- (NSOperation *)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMErrorCompletionBlock)completionBlock;

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock;

#pragma mark - Cancellation

- (void)cancelRequest:(id<VIMRequestToken>)request;

- (void)cancelAllRequests;

#pragma mark - Custom

- (id<VIMRequestToken>)fetchWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;

- (id<VIMRequestToken>)fetchWithRequestDescriptor:(VIMRequestDescriptor *)descriptor completionBlock:(VIMFetchCompletionBlock)completionBlock;

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

@end
