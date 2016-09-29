//
//  VIMClient.m
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

#import "VIMClient.h"
#import "VIMUser.h"
#import "VIMVideo.h"
#import "VIMComment.h"
#import "VIMCategory.h"
#import "VIMChannel.h"
#import "VIMTrigger.h"
#import "VIMRequestRetryManager.h"
#import "VIMSessionConfiguration.h"

static NSString *const ModelKeyPathData = @"data";

@interface VIMClient ()

@property (nonatomic, strong) VIMRequestRetryManager *retryManager;

@end

@implementation VIMClient

- (instancetype)initWithDefaultBaseURL
{
    return [self initWithBaseURL:[NSURL URLWithString:DefaultBaseURLString]];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        _retryManager = [[VIMRequestRetryManager alloc] initWithName:@"VIMClientRetryManager" operationManager:self];
    }
    
    return self;
}

#pragma mark - Custom

- (id<VIMRequestToken>)requestDescriptor:(VIMRequestDescriptor *)descriptor completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    __weak typeof(self) weakSelf = self;
    return [super requestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }

        if (error && descriptor.shouldRetryOnFailure)
        {
            if ([strongSelf.retryManager scheduleRetryIfNecessaryForError:error requestDescriptor:descriptor])
            {
                NSLog(@"VIMClient Retrying Request: %@", descriptor.urlPath);
            }
        }
        
        if (completionBlock)
        {
            completionBlock(response, error);
        }
        
    }];
}

#pragma mark - Utilities

- (id<VIMRequestToken>)resetPasswordWithEmail:(NSString *)email completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(email);
    
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = [NSString stringWithFormat:@"/users/%@/password/reset", email];
    descriptor.HTTPMethod = HTTPMethodPOST;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - General

- (nullable id<VIMRequestToken>)modelObjectWithURI:(nonnull NSString *)URI modelClass:(Class)modelClass completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = modelClass;
    descriptor.modelKeyPath = @"";
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)checkExistence:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodGET;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Users

- (id<VIMRequestToken>)userWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = @"";
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)usersWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = ModelKeyPathData;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)updateUserWithURI:(NSString *)URI name:(NSString *)name location:(NSString *)location bio:(NSString *)bio completionBlock:(VIMRequestCompletionBlock)completionBlock;
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPATCH;
    descriptor.shouldRetryOnFailure = NO;
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:name ? name : [NSNull null]  forKey:@"name"];
    [parameters setObject:location ? location : [NSNull null]  forKey:@"location"];
    [parameters setObject:bio ? bio : [NSNull null] forKey:@"bio"];
    
    descriptor.parameters = parameters;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)followUserWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleFollowUserWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unfollowUserWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleFollowUserWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleFollowUserWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleURI:URI newValue:newValue completionBlock:completionBlock];
}

#pragma mark - Categories

- (nullable id<VIMRequestToken>)categoryWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMCategory class];
    descriptor.modelKeyPath = @"";
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (nullable id<VIMRequestToken>)toggleFollowCategoryWithURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock
{
    return [self toggleURI:URI newValue:newValue completionBlock:completionBlock];
}

#pragma mark - Channels

- (nullable id<VIMRequestToken>)channelWithURI:(nonnull NSString *)URI completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMChannel class];
    descriptor.modelKeyPath = @"";
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (nullable id<VIMRequestToken>)toggleFollowChannelWithURI:(nonnull NSString *)URI newValue:(BOOL)newValue completionBlock:(nonnull VIMRequestCompletionBlock)completionBlock
{
    return [self toggleURI:URI newValue:newValue completionBlock:completionBlock];
}

#pragma mark - Pictures

- (id<VIMRequestToken>)createPictureResourceForUserWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(URI != nil);

    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = [URI stringByAppendingString:@"/pictures"];
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.shouldRetryOnFailure = NO;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)deletePictureResourceWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(URI != nil);

    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)activatePictureResourceWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(URI != nil);

    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPATCH;
    descriptor.parameters = @{@"active" : @"true"};
    descriptor.shouldRetryOnFailure = NO;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - VOD

- (id<VIMRequestToken>)VODItemWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVODItem class];
    descriptor.parameters = @{@"_video_override" : @"true"};
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)VODVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.parameters = @{@"_video_override" : @"true"};
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Videos

- (id<VIMRequestToken>)videoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = @"";
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)videosWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = ModelKeyPathData;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)updateVideoWithURI:(NSString *)URI title:(NSString *)title description:(NSString *)description privacy:(NSString *)privacy completionHandler:(VIMRequestCompletionBlock)completionBlock
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (title && [title length]) // API explicitly disallows nil or empty strings for title [AH]
    {
        [parameters setObject:title forKey:@"name"];
    }
    
    if (description && [description length])
    {
        [parameters setObject:description forKey:@"description"];
    }
    
    if (privacy && [privacy length])
    {
        [parameters setObject:@{@"view" : privacy} forKey:@"privacy"];
    }
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPATCH;
    descriptor.parameters = parameters;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)likeVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleLikeVideoWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unlikeVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleLikeVideoWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleLikeVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)watchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleWatchLaterVideoWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unwatchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self toggleWatchLaterVideoWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleWatchLaterVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)deleteVideoWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)shareVideoWithURI:(NSString *)URI recipients:(NSArray *)recipients completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(recipients != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = [URI stringByAppendingString:@"/shared"];
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = recipients;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Search

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self searchVideosWithQuery:query filter:@"" completionBlock:completionBlock];
}

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query filter:(NSString *)filter completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = [NSString stringWithFormat:@"/videos"];
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = ModelKeyPathData;
    descriptor.parameters = @{@"filter" : filter, @"query" : query};
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Comments

- (id<VIMRequestToken>)postCommentWithURI:(NSString *)URI text:(NSString *)text completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(text != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = @{@"text" : text};
    descriptor.modelClass = [VIMComment class];
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)postReplyWithURI:(NSString *)URI text:(NSString *)text completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(text != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = @{@"text" : text};
    descriptor.modelClass = [VIMComment class];
    descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)commentsWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMComment class];
    descriptor.modelKeyPath = ModelKeyPathData;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = @"/tokens";
    descriptor.HTTPMethod = HTTPMethodDELETE;
//    TODO: descriptor.shouldRetryOnFailure = YES;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Private API

#pragma mark APNS

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (id<VIMRequestToken>)registerDeviceForPushNotificationsWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPUT;
    descriptor.parameters = parameters;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unregisterDeviceForPushNotificationWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    descriptor.parameters = parameters;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)addPushNotificationWithParameters:(NSDictionary *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = @"/triggers";
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.parameters = parameters;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchUserPushNotificationsWithCompletionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = @"/me/triggers";
    descriptor.HTTPMethod = HTTPMethodGET;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.modelKeyPath = ModelKeyPathData;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchDevicePushNotificationsWithURI:(NSString *)URI parameters:(NSArray *)parameters completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = [URI stringByAppendingPathComponent:@"triggers"];
    descriptor.HTTPMethod = HTTPMethodPUT;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.modelKeyPath = ModelKeyPathData;
    descriptor.parameters = parameters;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)viewPushNotificationWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodGET;
    descriptor.modelClass = [VIMTrigger class];
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)removePushNotificationWithURI:(NSString *)URI completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    
    return [self requestDescriptor:descriptor completionBlock:completionBlock];
}

#endif

@end
