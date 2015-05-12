//
//  VIMVimeoSession.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
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

#import "VIMSession.h"

#import "VIMAPIClient.h"
#import "VIMAPIClient+Private.h"
#import "VIMRequestOperationManager.h"
#import "VIMAccountStore.h"
#import "VIMCache.h"
#import "VIMReachability.h"
#import "VIMUser.h"
#import "VIMAccount.h"
#import "VIMRequestDescriptor.h"
#import "VIMServerResponseMapper.h"
#import "VIMRequestOperation.h"
#import "VIMServerResponse.h"
#import "VIMAccountManager.h"
#import "VIMAccountCredential.h"

NSString * const VIMSession_AuthenticatedUserDidChangeNotification = @"VIMSession_AuthenticatedUserDidChangeNotification";
NSString * const VIMSession_DidFinishLoadingNotification = @"VIMSession_DidFinishLoadingNotification";

NSString *VimeoBaseURLString = @"https://api.vimeo.com/";

@interface VIMSession ()
{
    VIMCache *_userCache;
}

@property (nonatomic, strong, readwrite) VIMAccount *account;
@property (nonatomic, strong, readwrite) VIMUser *authenticatedUser;
@property (nonatomic, strong, readwrite) VIMSessionConfiguration *configuration;

@property (nonatomic, strong) NSString *baseURLString;

@end

@implementation VIMSession

- (void)dealloc
{
    [self removeObservers];
}

+ (instancetype)sharedSession
{
    static VIMSession *__sharedSession;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        __sharedSession = [[self alloc] init];
    });
    
    return __sharedSession;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _baseURLString = VimeoBaseURLString;
    }
    
    return self;
}

#pragma mark - Public API

- (void)setupWithConfiguration:(VIMSessionConfiguration *)configuration completionBlock:(void(^)(BOOL success))completionBlock
{
    if (![configuration isValid])
    {
        NSAssert(NO, @"Cannot proceed with an invalid session configuration");
        
        if (completionBlock)
        {
            completionBlock(NO);
        }
        
        return;
    }
    
    _configuration = configuration;
    
    [VIMReachability sharedInstance];
    [VIMCache sharedCache];
    [VIMAccountStore sharedInstance];
    [VIMAPIClient sharedClient];
    [VIMRequestOperationManager sharedManager];
    
    [self addObservers];
    
    // create user cache
    [self userCache];
    
    [self setupNewAccount:nil withCompletionBlock:^{

        [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_DidFinishLoadingNotification object:self];

        if (completionBlock)
        {
            completionBlock(YES);
        }

    }];
}

- (void)refreshUserFromRemoteWithCompletionBlock:(void (^)(NSError *error))completionBlock
{
    if (self.account == nil || ![self.account isAuthenticated] || ![self.account.credential isUserCredential])
    {
        NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Unable to refresh user, no account or account is not authenticated." forKey:NSLocalizedDescriptionKey]];

        if (completionBlock)
        {
            completionBlock(error);
        }
        
        return;
    }
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.cachePolicy = VIMCachePolicy_NetworkOnly;
    descriptor.urlPath = @"/me";
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = @"";
    
    [self refreshAuthenticatedUserWithRequestDescriptor:descriptor handler:self completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        if (completionBlock)
        {
            completionBlock(error);
        }
        
    }];
}

- (void)changeBaseURLString:(NSString *)baseURLString
{
    _baseURLString = baseURLString;
}

- (void)logOut
{
    [[VIMAPIClient sharedClient] logoutWithCompletionBlock:nil];

    [[VIMAccountManager sharedInstance] logoutAccount:self.account];
    
    [[VIMCache sharedCache] removeAllObjects];
    [[self userCache] removeAllObjects];
    [[self appGroupUserCache] removeAllObjects];
    [[self appGroupSharedCache] removeAllObjects];
}

#pragma mark - Configuration

- (NSString *)vimeoClientKey
{
    return self.configuration.clientKey;
}

- (NSString *)vimeoClientSecret
{
    return self.configuration.clientSecret;
}

- (NSString *)vimeoScope
{
    return self.configuration.scope;
}

- (NSString *)backgroundSessionIdentifierApp
{
    return self.configuration.backgroundSessionIdentifierApp;
}

- (NSString *)backgroundSessionIdentifierExtension
{
    return self.configuration.backgroundSessionIdentifierExtension;
}

- (NSString *)sharedContainerID
{
    return self.configuration.sharedContainerID;
}

#pragma mark - Observers

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:VIMAccountStore_AccountsDidChangeNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)accountDidChange:(NSNotification *)notification // TODO: rename
{
    VIMAccount *changedAccount = [notification.userInfo objectForKey:VIMAccountStore_ChangedAccountKey];
    
    if (changedAccount && [changedAccount.accountType isEqualToString:(NSString *)kVIMAccountType_Vimeo])
    {
        [self setupNewAccount:changedAccount withCompletionBlock:nil];
    }
}

#pragma mark - Authentication

- (void)setCurrentAuthenticatedUser:(VIMUser *)newUser
{
    if (self.authenticatedUser == newUser) // TODO: unique id instead?
        return;

    NSDictionary *userInfo = (self.authenticatedUser != nil) ? @{@"old_user_object_id" : self.authenticatedUser.objectID} : @{};

    self.authenticatedUser = newUser;
    
    [self createUserCache];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:VIMSession_AuthenticatedUserDidChangeNotification object:self userInfo:userInfo];
}

- (void)setupNewAccount:(VIMAccount *)newAccount withCompletionBlock:(void (^)(void))completionBlock
{
    if (newAccount == nil)
    {
        NSArray *accounts = [[VIMAccountStore sharedInstance] accountsWithType:(NSString *)kVIMAccountType_Vimeo];
        if (accounts.count > 0)
        {
            newAccount = [accounts firstObject];
            
            for (VIMAccount *account in accounts)
            {
                if([account isAuthenticated])
                {
                    newAccount = account;
                    break;
                }
            }
        }
    }
    
    self.account = newAccount;
    
    [self updateUserForNewAccountWithCompletionBlock:completionBlock];
}

- (void)updateUserForNewAccountWithCompletionBlock:(void (^)(void))completionBlock
{
    // Check if we need to do anything. Go ahead only if needed
    if ( (self.account.credential != nil && ![self.account.credential isUserCredential]) || ([self.account isAuthenticated] && self.authenticatedUser != nil) || ([self.account isAuthenticated] == NO && self.authenticatedUser == nil) )
    {
        if (completionBlock)
        {
            completionBlock();
        }
        
        return;
    }
    
    [self setCurrentAuthenticatedUser:nil];

    [self loadAuthenticatedUserFromCacheWithCompletionBlock:^(VIMUser *user, NSError *error) {

        // Call completionBlock here, no matter what, so that launch doesn't depend on the remote refresh request. [AH]
        if (completionBlock)
        {
            completionBlock();
        }

        if (error)
        {
            NSLog(@"Error loading user from cache: %@", error.localizedDescription);
            return;
        }
        
        [self refreshUserFromRemoteWithCompletionBlock:^(NSError *error) {

            if (error)
            {
                NSLog(@"Error refreshing user from remote: %@", error.localizedDescription);
                
                NSHTTPURLResponse *urlResponse = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
                if (urlResponse)
                {
                    NSInteger statusCode = urlResponse.statusCode;
                    if (statusCode == 401)
                    {
                        self.account.credential = nil;
                    }
                }
            }
            
        }];
        
    }];
}

- (void)loadAuthenticatedUserFromCacheWithCompletionBlock:(void (^)(VIMUser *user, NSError *error))completionBlock
{
    if (self.account == nil || ![self.account isAuthenticated])
    {
        NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Could not refresh user. No account found or account is not authenticated." forKey:NSLocalizedDescriptionKey]];
        
        if (completionBlock)
        {
            completionBlock(nil, error);
        }
        
        return;
    }

    id serverResponse = self.account.serverResponse;
    if(serverResponse == nil)
    {
        NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Could not get user info. Invalid server response" forKey:NSLocalizedDescriptionKey]];
        
        if (completionBlock)
        {
            completionBlock(nil, error);
        }
        
        return;
    }
    
    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.modelClass = [VIMUser class];
    descriptor.modelKeyPath = @"user";
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@""]];
    VIMRequestOperation *operation = [[VIMRequestOperation alloc] initWithRequest:request];
    operation.descriptor = descriptor;

    [VIMServerResponseMapper responseFromJSON:serverResponse operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        VIMUser *user = ((VIMUser *)response.result);

        if (error || user == nil)
        {
            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        // Reset the cache
        // This enables us to load latest user model object from user specific cache
        _userCache = nil;
        _authenticatedUser = user;
        
        // Try to load latest cached user
        
        VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
        descriptor.cachePolicy = VIMCachePolicy_LocalOnly;
        descriptor.urlPath = user.uri;
        descriptor.modelClass = [VIMUser class];
        descriptor.modelKeyPath = @"";
        
        [self refreshAuthenticatedUserWithRequestDescriptor:descriptor handler:self completionBlock:^(VIMServerResponse *response, NSError *error) {
            
            if (error)
            {
                // Not found in cache
                // Force set the authenticated user

                _authenticatedUser = nil;
                [self setCurrentAuthenticatedUser:user];
            
            } // else, successfully restored latest object from cache
            
            if (completionBlock)
            {
                completionBlock(self.authenticatedUser, nil);
            }
            
        }];
    }];
}

- (id<VIMRequestToken>)refreshAuthenticatedUserWithRequestDescriptor:(VIMRequestDescriptor *)descriptor handler:(id)handler completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    if (self.account == nil || ![self.account isAuthenticated])
    {
        NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Could not refresh user. No account found or account is not authenticated." forKey:NSLocalizedDescriptionKey]];

        if (completionBlock)
        {
            completionBlock(nil, error);
        }
        
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    return [[VIMRequestOperationManager sharedManager] fetchWithRequestDescriptor:descriptor handler:handler completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        if (error || response == nil || response.result == nil)
        {
            if (error == nil)
            {
                error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Could not fetch user, response or response.result is nil." forKey:NSLocalizedDescriptionKey]];
            }

            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        VIMUser *user = response.result;
        [weakSelf setCurrentAuthenticatedUser:user];
        
        if (completionBlock)
        {
            completionBlock(response, nil);
        }
        
    }];
}

#pragma mark - User Cache

- (void)createUserCache
{
    if (self.authenticatedUser == nil)
    {
        _userCache = [VIMCache sharedCache];
    }
    else
    {
        NSString *userCacheName = [NSString stringWithFormat:@"user_%@", self.authenticatedUser.objectID];
        
        if(_userCache == nil || [_userCache.name isEqualToString:userCacheName] == NO)
        {
            _userCache = [[VIMCache alloc] initWithName:userCacheName];
        }
    }
}

- (VIMCache *)userCache
{
    if (_userCache == nil)
    {
        [self createUserCache];
    }
    
    return _userCache;
}

#pragma mark - App Group Cache

- (NSString *)appGroupCachesPath
{
    NSURL *groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.configuration.sharedContainerID];
    
    if (groupURL == nil)
    {
        NSLog(@"VIMVimeoSession: Couldn't find shared group URL.");
        
        return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    }

    return [[groupURL path] stringByAppendingPathComponent:@"Library/Caches"];
}

- (NSString *)appGroupTmpPath
{
    NSURL *groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.configuration.sharedContainerID];
    
    if (groupURL == nil)
    {
        NSLog(@"VIMVimeoSession: Couldn't find shared group URL.");

        return NSTemporaryDirectory();
    }
    
    // TODO: create a new tmp directory here
    //return [groupPath stringByAppendingPathComponent:@"tmp"];
    
    return [groupURL path];
}

- (NSString *)appGroupExportsDirectory
{
    NSString *uploadsDirectoryName = @"uploads";
    
    NSURL *groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.configuration.sharedContainerID];
    if (groupURL == nil)
    {
        NSLog(@"VIMVimeoSession: Couldn't find shared group URL.");
        
        return [NSTemporaryDirectory() stringByAppendingPathComponent:uploadsDirectoryName];
    }
    
    NSString *groupPath = [[groupURL path] stringByAppendingPathComponent:uploadsDirectoryName];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:groupPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"VIMVimeoSession: Unable to create export directory: %@", error);
        
        return [NSTemporaryDirectory() stringByAppendingPathComponent:uploadsDirectoryName];
    }

    return groupPath;
}

- (VIMCache *)appGroupSharedCache
{
    static VIMCache *_sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *basePath = [self appGroupCachesPath];
        _sharedCache = [[VIMCache alloc] initWithName:@"SharedCache" basePath:basePath];
    });
    
    return _sharedCache;
}

- (VIMCache *)appGroupUserCache
{
    VIMUser *user = self.authenticatedUser;
    if(user == nil)
    {
        return [self appGroupSharedCache];
    }
    else
    {
        NSString *cacheName = [self userCache].name;
        NSString *basePath = [self appGroupCachesPath];
        
        return [[VIMCache alloc] initWithName:cacheName basePath:basePath];
    }
}

@end
