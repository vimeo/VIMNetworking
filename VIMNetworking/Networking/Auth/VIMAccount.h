//
//  VIMAccount.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

@class VIMAccountCredential;

extern const NSString *kVIMAccountType_Vimeo;

@interface VIMAccount : NSObject 

@property (nonatomic, readonly) NSString *accountID;
@property (nonatomic, readonly) NSString *accountType;
@property (nonatomic, readonly) NSString *accountName;

@property (nonatomic, strong) VIMAccountCredential *credential;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, strong) NSMutableDictionary *userData;
@property (nonatomic, strong) id serverResponse;

- (instancetype)initWithAccountID:(NSString *)accountID accountType:(NSString *)accountType accountName:(NSString *)accountName;

- (BOOL)isAuthenticated;

- (void)deleteCredential;

@end
