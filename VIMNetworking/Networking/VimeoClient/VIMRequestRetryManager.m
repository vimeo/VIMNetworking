//
//  VIMRequestRetryManager.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/18/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMRequestRetryManager.h"

#import "VIMReachability.h"
#import "VIMRequestOperationManager.h"
#import "VIMSession.h"
#import "VIMCache.h"
#import "VIMRequestDescriptor.h"

static const NSInteger DefaultNumberOfRetries = 1;
static const NSInteger DefaultRetryDelayInSeconds = 5;

static NSString *CountKey = @"retry_count";
static NSString *DescriptorKey = @"descriptor";

@interface VIMRequestRetryManager ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) VIMRequestOperationManager *operationManager;
@property (nonatomic, strong) NSSet *errorCodes;
@property (nonatomic, assign) NSInteger numberOfRetriesPerRequest;

@property (nonatomic, strong) NSMutableDictionary *descriptorDictionary;

@end

@implementation VIMRequestRetryManager
{
    dispatch_queue_t _queue;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_operationManager cancelAllRequestsForHandler:self];
}

- (instancetype)initWithName:(NSString *)name operationManager:(VIMRequestOperationManager *)operationManager
{
    NSAssert(name != nil && operationManager != nil, @"VIMRequestRetryManager must be initialized with a name and operationManager.");

    self = [super init];
    if (self)
    {
        _name = name;
        _operationManager = operationManager;
        _descriptorDictionary = nil; // Must initialize to nil, _load takes care of the rest. [AH]
        
        _queue = dispatch_queue_create("VIMRequestRetryManage_ArchiveQueue", DISPATCH_QUEUE_SERIAL);
        
        _errorCodes = [VIMRequestRetryManager _defaultErrorCodes];
        _numberOfRetriesPerRequest = DefaultNumberOfRetries;
        
        [self _loadWithCompletionBlock:^{

            [self _retryAllDescriptors];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reachabilityOnline:) name:VIMReachabilityStatusChangeOnlineNotification object:nil];
        }];
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer initWithName:.");

    return nil;
}

#pragma mark - Public API

- (BOOL)scheduleRetryIfNecessaryForError:(NSError *)error requestDescriptor:(VIMRequestDescriptor *)descriptor
{
    NSAssert(descriptor.descriptorID != nil, @"descriptorID must not be nil");

    if (error == nil || descriptor == nil || descriptor.descriptorID == nil)
    {
        return NO;
    }
    
    NSHTTPURLResponse *urlResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    BOOL retryBasedOnStatusCode = (urlResponse && [urlResponse statusCode] >= 500 && [urlResponse statusCode] <= 599);

    if (retryBasedOnStatusCode == NO && ![self.errorCodes containsObject:@(error.code)])
    {
        return NO;
    }

    __weak typeof(self) welf = self;
    dispatch_async(_queue, ^{
        
        NSDictionary *dictionary = @{DescriptorKey : descriptor, CountKey : @(0)};
        [welf.descriptorDictionary setObject:dictionary forKey:descriptor.descriptorID];
        [welf _save];

        [welf scheduleRetryForDescriptor:descriptor];
        
    });
    
    return YES;
}

#pragma mark - Private API

- (void)scheduleRetryForDescriptor:(VIMRequestDescriptor *)descriptor
{
    NSLog(@"SCHEDULING RETRY %@", descriptor.descriptorID);

    __weak typeof(self) welf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DefaultRetryDelayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [welf _retryDescriptor:descriptor];
        
    });
}

- (void)_retryAllDescriptors
{
    NSArray *dictionaries = [self.descriptorDictionary allValues];

    if (![VIMReachability sharedInstance].isNetworkReachable || [dictionaries count] == 0)
    {
        return;
    }

    NSLog(@"RETRYING ALL");

    for (NSDictionary *dictionary in dictionaries)
    {
        VIMRequestDescriptor *descriptor = dictionary[DescriptorKey];
        [self _retryDescriptor:descriptor];
    }
}

- (void)_retryDescriptor:(VIMRequestDescriptor *)descriptor
{
    if (![VIMReachability sharedInstance].isNetworkReachable)
    {
        NSLog(@"OFFLINE NOT RETRYING %@", descriptor.descriptorID);

        return;
    }
    
    NSLog(@"RETRYING %@", descriptor.descriptorID);

    __weak typeof(self) welf = self;
    [self.operationManager fetchWithRequestDescriptor:descriptor handler:self completionBlock:^(VIMServerResponse *response, NSError *error) {
        
        if (error)
        {
            NSLog(@"Error retrying request: %@", error);
        }
        
        dispatch_async(_queue, ^{
            
            NSDictionary *dictionary = welf.descriptorDictionary[descriptor.descriptorID];
            NSNumber *number = dictionary[CountKey];
            if (number)
            {
                NSInteger count = number.integerValue + 1;
                if (count >= DefaultNumberOfRetries)
                {
                    NSLog(@"RETRIED %lu TIMES, REMOVING", (long)count);
                    [welf.descriptorDictionary removeObjectForKey:descriptor.descriptorID];
                }
                else
                {
                    NSLog(@"RETRIED %lu TIMES", (long)count);
                    NSMutableDictionary *updated = [NSMutableDictionary dictionary];
                    updated[DescriptorKey] = descriptor;
                    updated[CountKey] = @(count);
                    [welf.descriptorDictionary setObject:updated forKey:descriptor.descriptorID];
                    
                    [welf scheduleRetryForDescriptor:descriptor];
                }
            }

            [welf _save];
            
        });
        
    }];
}

#pragma mark - Notifications

- (void)_reachabilityOnline:(NSNotification *)notification
{
    [self _retryAllDescriptors];
}

#pragma mark - Archiving

- (void)_loadWithCompletionBlock:(void (^)(void))completionBlock
{
    __weak typeof(self) welf = self;
    dispatch_async(_queue, ^{
       
        [[[VIMSession sharedSession] userCache] objectForKey:welf.name completionBlock:^(NSDictionary *dictionary) {

            if (dictionary)
            {
                welf.descriptorDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
            }
            else
            {
                welf.descriptorDictionary = [NSMutableDictionary dictionary];
            }
            
            NSLog(@"LOADED %lu DESCRIPTORS", (unsigned long)[welf.descriptorDictionary count]);
            
            if (completionBlock)
            {
                completionBlock();
            }

        }];
        
    });
}

- (void)_save
{
    __weak typeof(self) welf = self;
    dispatch_async(_queue, ^{
        
        NSLog(@"SAVED %lu DESCRIPTORS", (unsigned long)[welf.descriptorDictionary count]);

        [[[VIMSession sharedSession] userCache] setObject:welf.descriptorDictionary forKey:welf.name];
        
    });
}

#pragma mark - Utilities

+ (NSSet *)_defaultErrorCodes
{
    return [NSSet setWithObjects:
             @(NSURLErrorTimedOut),
             @(NSURLErrorCannotFindHost),
             @(NSURLErrorCannotConnectToHost),
             @(NSURLErrorDNSLookupFailed),
             @(NSURLErrorNotConnectedToInternet),
             @(NSURLErrorNetworkConnectionLost),
             nil];
}

@end
