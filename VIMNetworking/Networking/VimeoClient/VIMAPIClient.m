//
//  VIMAPIManager.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/20/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMAPIClient.h"
#import "VIMAccountManager+Private.h"
#import "VIMRequestDescriptor.h"
#import "VIMNetworking.h"
#import "VIMAccountManager.h"
#import "VIMUser.h"
#import "VIMVideo.h"
#import "VIMComment.h"
#import "VIMTrigger.h"
#import "VIMSession.h"
#import "VIMSessionConfiguration.h"
#import "VIMOAuthAuthenticator.h"
#import "VIMAccount.h"
#import "VIMRequestRetryManager.h"

static NSString *kDataKeyPath = @"data";
static NSString *VIMAPIClient_RetryManagerName = @"VIMAPIClient";

@interface VIMAPIClient ()

@property (nonatomic, weak) id handler;

@property (nonatomic, strong) NSString *state;

@property (nonatomic, strong) VIMRequestRetryManager *retryManager;

@property (nonatomic, strong) VIMRequestOperationManager *operationManager;

@end

@implementation VIMAPIClient

- (void)dealloc
{
    [self cancelAllRequests];
}

+ (instancetype)sharedClient
{
    static VIMAPIClient *__sharedClient;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        __sharedClient = [[self alloc] initWithHandler:self operationManager:[VIMRequestOperationManager sharedManager]];
    });
    
    return __sharedClient;
}

- (instancetype)initWithHandler:(id)handler operationManager:(VIMRequestOperationManager *)operationManager
{
    self = [super init];
    if (self)
    {
        _handler = handler;
        _operationManager = operationManager;
        _state = [NSProcessInfo processInfo].globallyUniqueString;
        _retryManager = [[VIMRequestRetryManager alloc] initWithName:VIMAPIClient_RetryManagerName operationManager:operationManager];
    }
    
    return self;
}

#pragma mark - Authentication

- (NSURL *)codeGrantAuthorizationURL
{
    VIMSessionConfiguration *sessionConfiguration = [VIMSession sharedSession].configuration;
    
    if (!sessionConfiguration)
    {
        return nil;
    }
    
    NSString *clientKey = sessionConfiguration.clientKey;
    NSString *redirectURI = [self codeGrantRedirectURI];
    NSString *clientScope = sessionConfiguration.scope;
    NSString *state = self.state;
    
    NSDictionary *parameters = @{@"response_type":@"code",
                                 @"client_id":clientKey,
                                 @"redirect_uri":redirectURI,
                                 @"scope":clientScope,
                                 @"state":state};
    
    NSString *authenticationURLString = @"https://api.vimeo.com/oauth/authorize";
    
    NSError *error;
    NSMutableURLRequest *urlRequest = [self.operationManager.requestSerializer requestWithMethod:@"GET" URLString:authenticationURLString parameters:parameters error:&error];
    
    if (error)
    {
        return nil;
    }
    
    return urlRequest.URL;
}

- (NSString *)codeGrantRedirectURI
{
    if (![VIMSession sharedSession].configuration)
        return nil;
    
    NSString *authRedirectScheme = [NSString stringWithFormat:@"vimeo%@", [VIMSession sharedSession].configuration.clientKey];
    NSString *authRedirectPath = @"auth";
    
    return [NSString stringWithFormat:@"%@://%@", authRedirectScheme, authRedirectPath];
}

- (NSOperation *)authenticateWithClientCredentialsGrant:(VIMErrorCompletionBlock)completionBlock
{
    return [[VIMAccountManager sharedInstance] authenticateWithClientCredentialsGrantAndCompletionBlock:completionBlock];
}

- (NSOperation *)authenticateWithCodeGrantResponseURL:(NSURL *)responseURL completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSString *parameterString = responseURL.query;
    NSDictionary *responseParameters = VIMParametersFromQueryString(parameterString);
    NSString *code = responseParameters[@"code"];
    NSString *state = responseParameters[@"state"];
    
    if ( !code || !state || ![state isEqualToString:self.state] )
    {
        NSError *error = [NSError errorWithDomain:@"Error" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Invalid parameters for code grant response url"}];
        
        if (completionBlock)
        {
            completionBlock(error);
        }
        
        return nil;
    }
    
    return [[VIMAccountManager sharedInstance] authenticateWithCodeGrant:code completionBlock:completionBlock];
}

#pragma mark - Cancellation

- (void)cancelRequest:(id<VIMRequestToken>)request
{
    [self.operationManager cancelRequest:request];
}

- (void)cancelAllRequests
{
    [self.operationManager cancelAllRequestsForHandler:self.handler];
}

#pragma mark - Custom

- (id<VIMRequestToken>)fetchWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchWithRequestDescriptor:(VIMRequestDescriptor *)descriptor completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSParameterAssert([descriptor.urlPath length] != 0);
    
    return [self.operationManager fetchWithRequestDescriptor:descriptor handler:self.handler completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        if (error && descriptor.shouldRetryOnFailure)
        {
            if ([self.retryManager scheduleRetryIfNecessaryForError:error requestDescriptor:descriptor])
            {
                NSLog(@"VIMAPIClient Retrying Request: %@", descriptor.urlPath);
            }
        }
        
        if (completionBlock)
        {
            completionBlock(response, error);
        }
        
    }];
}

#pragma mark - Users

- (id<VIMRequestToken>)userWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = @"";
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)usersWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = kDataKeyPath;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)updateUserWithURI:(NSString *)URI username:(NSString *)username location:(NSString *)location completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSParameterAssert(username != nil && location != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPATCH;
    descriptor.parameters = @{@"name" : username, @"location" : location};
    descriptor.shouldRetryOnFailure = YES;

    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)followUserWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleFollowUserWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unfollowUserWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleFollowUserWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleFollowUserWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Videos

- (id<VIMRequestToken>)videoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock;
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = @"";
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)videosWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = kDataKeyPath;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)updateVideoWithURI:(NSString *)URI title:(NSString *)title description:(NSString *)description privacy:(NSString *)privacy completionHandler:(VIMFetchCompletionBlock)completionBlock
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if(title != nil && [title length] != 0) // API explicitly disallows nil or empty strings for title [AH]
        [parameters setObject:title forKey:@"name"];
    
    if(description != nil)
        [parameters setObject:description forKey:@"description"];
    
    if(privacy != nil && privacy.length > 0)
        [parameters setObject:@{@"view" : privacy} forKey:@"privacy"];
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPATCH;
    descriptor.parameters = parameters;
    descriptor.shouldRetryOnFailure = YES;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)likeVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleLikeVideoWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unlikeVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleLikeVideoWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleLikeVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)watchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleWatchLaterVideoWithURI:URI newValue:YES completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unwatchLaterVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self toggleWatchLaterVideoWithURI:URI newValue:NO completionBlock:completionBlock];
}

- (id<VIMRequestToken>)toggleWatchLaterVideoWithURI:(NSString *)URI newValue:(BOOL)newValue completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = ( newValue ? HTTPMethodPUT : HTTPMethodDELETE );
    descriptor.shouldRetryOnFailure = YES;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)deleteVideoWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    descriptor.shouldRetryOnFailure = YES;

    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)shareVideoWithURI:(NSString *)URI recipients:(NSArray *)recipients completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSParameterAssert(recipients != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = [URI stringByAppendingString:@"/shared"];
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = recipients;
    descriptor.shouldRetryOnFailure = YES;

    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Search

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    return [self searchVideosWithQuery:query filter:@"" completionBlock:completionBlock];
}

- (id<VIMRequestToken>)searchVideosWithQuery:(NSString *)query filter:(NSString *)filter completionBlock:(VIMFetchCompletionBlock)completionBlock
{
	VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = [NSString stringWithFormat:@"/videos"];
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = kDataKeyPath;
    descriptor.parameters = @{@"filter" : filter, @"query" : query};
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Comments

- (id<VIMRequestToken>)postCommentWithURI:(NSString *)URI text:(NSString *)text completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSParameterAssert(text != nil);
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = @{@"text" : text};
    descriptor.shouldRetryOnFailure = YES;

    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)commentsWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = URI;
    descriptor.modelClass = [VIMComment class];
    descriptor.modelKeyPath = kDataKeyPath;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark - Private API

#pragma mark Authentication

- (id<VIMRequestToken>)logoutWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = @"/tokens";
    descriptor.HTTPMethod = HTTPMethodDELETE;
    //    descriptor.shouldRetryOnFailure = YES;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    return [[VIMAccountManager sharedInstance] loginWithEmail:email password:password completionBlock:completionBlock];
}

- (NSOperation *)joinWithDisplayName:(NSString *)displayName email:(NSString *)email password:(NSString *)password completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    return [[VIMAccountManager sharedInstance] joinWithDisplayName:displayName email:email password:password completionBlock:completionBlock];
}

- (NSOperation *)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMBooleanCompletionBlock)completionBlock
{
    return [[VIMAccountManager sharedInstance] loginWithFacebookToken:facebookToken completionBlock:completionBlock];
}

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    return [[VIMAccountManager sharedInstance] joinWithFacebookToken:facebookToken completionBlock:completionBlock];
}

- (id<VIMRequestToken>)resetPasswordWithEmail:(NSString *)email completionBlock:(VIMErrorCompletionBlock)completionBlock
{
    NSParameterAssert(email);
    
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = [NSString stringWithFormat:@"/users/%@/password/reset", email];
    descriptor.HTTPMethod = HTTPMethodPOST;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error)
            {
                if (completionBlock)
                {
                    completionBlock(error);
                }
            }];
}

#pragma mark Misc

- (id<VIMRequestToken>)logErrorWithParameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSParameterAssert(parameters != nil);
    
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = @"/errors?platform=ios";
    descriptor.HTTPMethod = HTTPMethodPUT;
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)startTwitterReverseOAuthWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = @"_ios/me/twitter/reverse_auth/start";
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)connectSocialServiceWithParameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = @"me/services";
    descriptor.modelKeyPath = kDataKeyPath;
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchConnectedServicesWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.urlPath = @"me/services";
    descriptor.modelKeyPath = kDataKeyPath;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#pragma mark APNS

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (id<VIMRequestToken>)registerDeviceForPushNotificationsWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodPUT;
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)unregisterDeviceForPushNotificationWithURI:(NSString *)URI parameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)addPushNotificationWithParameters:(NSDictionary *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = @"/triggers";
    descriptor.HTTPMethod = HTTPMethodPOST;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchUserPushNotificationsWithCompletionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = @"/me/triggers";
    descriptor.HTTPMethod = HTTPMethodGET;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.modelKeyPath = kDataKeyPath;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)fetchDevicePushNotificationsWithURI:(NSString *)URI parameters:(NSArray *)parameters completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = [URI stringByAppendingPathComponent:@"triggers"];
    descriptor.HTTPMethod = HTTPMethodPUT;
    descriptor.modelClass = [VIMTrigger class];
    descriptor.modelKeyPath = kDataKeyPath;
    descriptor.parameters = parameters;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)viewPushNotificationWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodGET;
    descriptor.modelClass = [VIMTrigger class];
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

- (id<VIMRequestToken>)removePushNotificationWithURI:(NSString *)URI completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    VIMRequestDescriptor *descriptor = [VIMRequestDescriptor new];
    descriptor.urlPath = URI;
    descriptor.HTTPMethod = HTTPMethodDELETE;
    
    return [self fetchWithRequestDescriptor:descriptor completionBlock:completionBlock];
}

#endif

#pragma mark Utilities

NSDictionary *VIMParametersFromQueryString(NSString *queryString)
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (queryString)
    {
        NSScanner *parameterScanner = [[NSScanner alloc] initWithString:queryString];
        NSString *name = nil;
        NSString *value = nil;
        
        while (![parameterScanner isAtEnd])
        {
            name = nil;
            [parameterScanner scanUpToString:@"=" intoString:&name];
            [parameterScanner scanString:@"=" intoString:NULL];
            
            value = nil;
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:NULL];
            
            if (name && value)
            {
                [parameters setValue:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    
    return parameters;
}

@end
