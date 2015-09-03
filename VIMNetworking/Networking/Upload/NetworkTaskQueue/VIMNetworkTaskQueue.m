//
//  VIMNetworkTaskQueue.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/8/15.
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

#import "VIMNetworkTaskQueue.h"
#import "VIMNetworkTaskSessionManager.h"
#import "VIMTaskQueueDebugger.h"
#import "VIMNetworkTask.h"
#import "VIMTaskQueueArchiver.h"
#import "AFNetworkReachabilityManager.h"

NSString *const VIMNetworkTaskQueue_DidSuspendOrResumeNotification = @"VIMNetworkTaskQueue_DidSuspendOrResumeNotification";

static const NSString *ArchiveKey = @"network_queue_archive";
static const NSString *SuspendedByUserKey = @"suspended_by_user";
static const NSString *CellularEnabledKey = @"cellular_enabled";

@interface VIMNetworkTaskQueue ()

@property (nonatomic, strong) VIMNetworkTaskSessionManager *sessionManager;

@property (nonatomic, assign, getter=isSuspendedByUser) BOOL suspendedByUser;

@end

@implementation VIMNetworkTaskQueue

- (void)dealloc
{
    [VIMTaskQueueDebugger postLocalNotificationWithContext:self.name message:@"DEALLOC"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithSessionManager:(VIMNetworkTaskSessionManager *)sessionManager
{
    NSParameterAssert(sessionManager);
    
    if (!sessionManager)
    {
        return nil;
    }
    
    NSString *sharedContainerID = nil;
    
    if ([sessionManager.session.configuration respondsToSelector:@selector(sharedContainerIdentifier)])
    {
        sharedContainerID = [sessionManager.session.configuration sharedContainerIdentifier];
    }
    
    VIMTaskQueueArchiver *archiver = [[VIMTaskQueueArchiver alloc] initWithSharedContainerID:sharedContainerID];
    
    self = [super initWithName:sessionManager.session.configuration.identifier archiver:archiver];
    if (self)
    {
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.name message:@"INIT"];
        
        _sessionManager = sessionManager;
        
        [self loadCommonSettings];
        
        [self resumeIfAllowed];
        
        [self addObservers];
    }
    
    return self;
}

#pragma mark - Private API

- (void)resumeIfAllowed
{
    if (self.isSuspendedByUser == NO)
    {
        [self resume];
    }
}

#pragma mark - Superclass Overrides

- (void)prepareTask:(VIMTask *)task
{
    if (!task)
    {
        return;
    }
    
    VIMNetworkTask *networkTask = (VIMNetworkTask *)task;
    
    if (networkTask.sessionManager == nil)
    {
        networkTask.sessionManager = self.sessionManager;
    }
}

- (void)suspend
{
    [super suspend];
    
    self.suspendedByUser = YES;
    
    [self notifyOfStateChange];
}

- (void)resume
{
    if ([AFNetworkReachabilityManager sharedManager].isReachable == NO)
    {
        return;
    }
    
    if ([AFNetworkReachabilityManager sharedManager].isReachableViaWWAN && self.isCellularUploadEnabled == NO)
    {
        return;
    }
    
    [super resume];
    
    self.suspendedByUser = NO;
    
    [self notifyOfStateChange];
}

#pragma mark - Accessor Overrides

- (void)setSuspendedByUser:(BOOL)suspendedByUser
{
    if (_suspendedByUser != suspendedByUser)
    {
        _suspendedByUser = suspendedByUser;
        
        [self saveCommonSettings];
    }
}

- (void)setCellularUploadEnabled:(BOOL)cellularUploadEnabled
{
    if (_cellularUploadEnabled != cellularUploadEnabled)
    {
        _cellularUploadEnabled = cellularUploadEnabled;
        
        [self saveCommonSettings];
        
        if ([AFNetworkReachabilityManager sharedManager].isReachableViaWWAN)
        {
            if (_cellularUploadEnabled)
            {
                [self resumeIfAllowed];
            }
            else
            {
                [super suspend];
                
                [self notifyOfStateChange];
            }
        }
    }
}

#pragma mark - Notifications

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityNotification:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
}

- (void)reachabilityNotification:(NSNotification *)notification
{
    if ([AFNetworkReachabilityManager sharedManager].isReachable)
    {
        [self online];
    }
    else
    {
        [self offline];
    }
}

- (void)online
{
    if ([AFNetworkReachabilityManager sharedManager].isReachableViaWWAN)
    {
        if (self.cellularUploadEnabled)
        {
            [self resumeIfAllowed];
        }
        else
        {
            [super suspend];
            
            [self notifyOfStateChange];
        }
    }
    else if ([AFNetworkReachabilityManager sharedManager].isReachableViaWiFi)
    {
        [self resumeIfAllowed];
    }
}

- (void)offline
{
    [super suspend];
    
    [self notifyOfStateChange];
}

- (void)notifyOfStateChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIMNetworkTaskQueue_DidSuspendOrResumeNotification object:nil];
    });
}

#pragma mark - Archival

// Note: We use the same archive key for both app and extension
// because the values being archived apply to both app and extension
// (they're global settings) [AH]

- (void)loadCommonSettings
{
    NSDictionary *dictionary = [self.archiver loadObjectForKey:(NSString *)ArchiveKey];
    
    if (dictionary[CellularEnabledKey])
    {
        self.cellularUploadEnabled = [dictionary[CellularEnabledKey] boolValue];
    }
    else
    {
        self.cellularUploadEnabled = YES;
    }
    
    self.suspendedByUser = [dictionary[SuspendedByUserKey] boolValue];
}

- (void)saveCommonSettings
{
    NSDictionary *dictionary = @{CellularEnabledKey : @(self.isCellularUploadEnabled), SuspendedByUserKey : @(self.isSuspendedByUser)};
    
    [self.archiver saveObject:dictionary forKey:(NSString *)ArchiveKey];
}

@end
