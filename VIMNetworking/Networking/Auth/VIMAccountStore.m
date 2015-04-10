//
//  VIMAccountStore.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMAccountStore.h"

#import "VIMAccount.h"
#import "VIMCache.h"
#import "VIMNetworking.h"
#import "KeychainUtility.h"

static NSString * const kVIMAccountStore_SaveKey = @"kVIMAccountStore_SaveKey";

NSString * const VIMAccountStore_AccountsDidChangeNotification = @"VIMAccountStore_AccountsDidChangeNotification";

NSString * const VIMAccountStore_ChangedAccountKey = @"VIMAccountStore_ChangedAccountKey";


@interface VIMAccountStore ()

@property (nonatomic, strong) NSMutableArray *accounts;

@end

@implementation VIMAccountStore

+ (VIMAccountStore *)sharedInstance
{
    static VIMAccountStore *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[VIMAccountStore alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _accounts = [NSMutableArray array];
        
        [self _load];
    }
    
    return self;
}

- (void)saveAccount:(VIMAccount *)account
{
    VIMAccount *existingAccount = [self accountWithID:account.accountID];
    if(account != existingAccount)
    {
        if(existingAccount)
            [self.accounts removeObject:existingAccount];
        
        [self.accounts addObject:account];
    }
    
    [self _save];
    
    [self sendAccountChangeNotification:account];
}

- (void)removeAccount:(VIMAccount *)account
{
    VIMAccount *existingAccount = [self accountWithID:account.accountID];
    if(existingAccount)
        [self.accounts removeObject:existingAccount];

    [self _save];

    [self sendAccountChangeNotification:account];
}

- (VIMAccount *)accountWithID:(NSString *)accountID
{
    for(VIMAccount *account in self.accounts)
    {
        if([account.accountID isEqualToString:accountID])
            return account;
    }
    
    return nil;
}

- (NSArray *)accountsWithType:(NSString *)accountType
{
    NSMutableArray *result = [NSMutableArray array];
    
    for(VIMAccount *account in self.accounts)
    {
        if([account.accountType isEqualToString:accountType])
            [result addObject:account];
    }
    
    return result;
}

- (void)sendAccountChangeNotification:(VIMAccount *)account
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if(account)
        [userInfo setObject:account forKey:VIMAccountStore_ChangedAccountKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIMAccountStore_AccountsDidChangeNotification object:self userInfo:userInfo];
}

- (void)reload
{
    [self _load];
    
    NSArray *accounts = self.accounts;
    
    for(VIMAccount *account in accounts)
        [self sendAccountChangeNotification:account];
}

#pragma mark - Internal methods

- (void)_save
{
    NSArray *accountsToSave = [NSArray arrayWithArray:self.accounts];

    // No longer using cache for account data [AH]
//    VIMCache *cache = [[VIMSession sharedSession] appGroupSharedCache];
//    [cache setObject:accountsToSave forKey:(NSString *)kVIMAccountStore_SaveKey];
    
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [keyedArchiver encodeObject:accountsToSave];
    [keyedArchiver finishEncoding];

    BOOL success = [[KeychainUtility sharedInstance] setData:data forAccount:kVIMAccountStore_SaveKey];
    if (!success)
    {
        NSLog(@"Unable to archive account data.");
    }
}

- (void)_load
{
    [self.accounts removeAllObjects];

    NSArray *accounts = nil;
    
    NSData *data = [[KeychainUtility sharedInstance] dataForAccount:(NSString *)kVIMAccountStore_SaveKey];
    if (data)
    {
        NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        @try
        {
            accounts = [keyedUnarchiver decodeObject];
        }
        @catch (NSException *exception)
        {
            NSLog(@"VIMAccountStore: An exception occured while unarchiving: %@", exception);
            
            [[KeychainUtility sharedInstance] deleteDataForAccount:(NSString *)kVIMAccountStore_SaveKey];
        }
        
        [keyedUnarchiver finishDecoding];
    }
    
    // Migrate from cache if necessary [AH]
    if (accounts == nil)
    {
        VIMCache *cache = [[VIMSession sharedSession] appGroupSharedCache];
        accounts = [cache objectForKey:(NSString *)kVIMAccountStore_SaveKey];
        
        if (accounts)
        {
            [self.accounts addObjectsFromArray:accounts];
        
            [self _save];

            [cache removeObjectForKey:(NSString *)kVIMAccountStore_SaveKey];
        }
    }
    else
    {
        [self.accounts addObjectsFromArray:accounts];
    }
}

@end
