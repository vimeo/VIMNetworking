//
//  VIMAccount.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMAccount.h"
#import "VIMAccountCredential.h"

const NSString *kVIMAccountType_Vimeo = @"VIMAccountType_Vimeo";

@interface VIMAccount () <NSCoding, NSSecureCoding>

@property (nonatomic, strong, readwrite) NSString *accountID;
@property (nonatomic, strong, readwrite) NSString *accountType;
@property (nonatomic, strong, readwrite) NSString *accountName;

@end

@implementation VIMAccount

- (instancetype)initWithAccountID:(NSString *)accountID accountType:(NSString *)accountType accountName:(NSString *)accountName
{
    self = [super init];
    if (self)
    {
        _accountID = accountID;
        _accountType = accountType;
        _accountName = accountName;
        _userData = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (BOOL)isAuthenticated
{
    return (self.credential != nil && self.credential.accessToken != nil);
}

- (void)deleteCredential
{
    if (self.credential)
    {
        self.credential = nil;
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.accountID = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accountID"];
        self.accountType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accountType"];
        self.accountName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accountName"];

        // TODO: need to use decodeObjectOfClass but this is type id, what to do? [AH]
        
        id response = nil;
        @try
        {
            response = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"serverResponse"];
        }
        @catch (NSException *exception)
        {
            @try
            {
                response = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"serverResponse"];
            }
            @catch (NSException *exception)
            {
                NSLog(@"Unable to unarchive server response");
            }
        }

        self.username = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"username"];
        self.serverResponse = response;
        self.userData = [aDecoder decodeObjectOfClass:[NSMutableDictionary class] forKey:@"userData"];
        self.credential = [aDecoder decodeObjectOfClass:[VIMAccountCredential class] forKey:@"credential"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accountID forKey:@"accountID"];
    [aCoder encodeObject:self.accountType forKey:@"accountType"];
    [aCoder encodeObject:self.accountName forKey:@"accountName"];
    
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.serverResponse forKey:@"serverResponse"];
    [aCoder encodeObject:self.userData forKey:@"userData"];
    [aCoder encodeObject:self.credential forKey:@"credential"];
}

@end
