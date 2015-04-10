//
//  VIMAccountCredential.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/29/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMAccountCredential.h"
#import "VIMOAuthAuthenticator.h"

@interface VIMAccountCredential () <NSCoding, NSSecureCoding>

@end

@implementation VIMAccountCredential

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
        self.tokenType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"tokenType"];
        self.refreshToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"refreshToken"];
        self.expirationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"expirationDate"];
        self.grantType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"grantType"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:self.tokenType forKey:@"tokenType"];
    [aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:self.expirationDate forKey:@"expirationDate"];
    [aCoder encodeObject:self.grantType forKey:@"grantType"];
}

#pragma mark - Public API

- (BOOL)isUserCredential
{
    return (![self.grantType isEqualToString:kVIMOAuthGrantType_ClientCredentials]);
}

- (BOOL)isExpired
{
    return self.expirationDate && [self.expirationDate timeIntervalSinceNow] >= 0;
}

@end
