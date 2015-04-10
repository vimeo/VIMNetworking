//
//  VIMAccountStore.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

@class VIMAccount;

extern NSString * const VIMAccountStore_AccountsDidChangeNotification;

extern NSString * const VIMAccountStore_ChangedAccountKey;

@interface VIMAccountStore : NSObject

+ (VIMAccountStore *)sharedInstance;

- (void)saveAccount:(VIMAccount *)account;
- (void)removeAccount:(VIMAccount *)account;

- (VIMAccount *)accountWithID:(NSString *)accountID;
- (NSArray *)accountsWithType:(NSString *)accountType;

- (void)reload;

@end
