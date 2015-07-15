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
#import "VIMReachability.h"
#import "VIMSession.h" // TODO: eliminate this dependency [AH]
#import "VIMTaskQueueDebugger.h"
#import "VIMNetworkTask.h"

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
    self = [super initWithName:sessionManager.session.configuration.identifier];
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

- (NSUserDefaults *)taskQueueDefaults
{
    NSString *sharedContainerID = [VIMSession sharedSession].configuration.sharedContainerID;
    
    if (sharedContainerID)
    {
        return [[NSUserDefaults alloc] initWithSuiteName:sharedContainerID];
    }
    else
    {
        return [NSUserDefaults standardUserDefaults];
    }
}

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
    if ([[VIMReachability sharedInstance] isNetworkReachable] == NO)
    {
        return;
    }
    
    if ([[VIMReachability sharedInstance] isOn3G] && self.isCellularUploadEnabled == NO)
    {
        self.cellularUploadEnabled = YES;
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
        
        if ([[VIMReachability sharedInstance] isOn3G])
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineNotification:) name:VIMReachabilityStatusChangeOnlineNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(offlineNotification:) name:VIMReachabilityStatusChangeOfflineNotification object:nil];
}

- (void)onlineNotification:(NSNotification *)notification
{
    if ([[VIMReachability sharedInstance] isOn3G])
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
    else if ([[VIMReachability sharedInstance] isOnWiFi])
    {
        [self resumeIfAllowed];
    }
}

- (void)offlineNotification:(NSNotification *)notification
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
    NSUserDefaults *sharedDefaults = [self taskQueueDefaults];
    
    NSDictionary *dictionary = [sharedDefaults objectForKey:(NSString *)ArchiveKey];
    
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
    NSUserDefaults *sharedDefaults = [self taskQueueDefaults];
    
    NSDictionary *dictionary = @{CellularEnabledKey : @(self.isCellularUploadEnabled), SuspendedByUserKey : @(self.isSuspendedByUser)};
    
    [sharedDefaults setObject:dictionary forKey:(NSString *)ArchiveKey];
    [sharedDefaults synchronize];
}

@end
