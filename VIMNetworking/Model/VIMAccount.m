//
//  VIMAccount.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
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

#import "VIMAccount.h"
#import "VIMUser.h"

@interface VIMAccount () <NSCoding, NSSecureCoding>

@end

@implementation VIMAccount

#pragma mark - Public API

- (BOOL)isAuthenticated
{
    return [self.accessToken length] > 0 && [[self.tokenType lowercaseString] isEqualToString:@"bearer"];
}

- (BOOL)isAuthenticatedWithUser
{
    return [self isAuthenticated] && self.user;
}

- (BOOL)isAuthenticatedWithClientCredentials
{
    return [self isAuthenticated] && !self.user;
}

#pragma mark - VIMMappable

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"user"])
    {
        return [VIMUser class];
    }
    
    return nil;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark - NSCoding

+ (void)load
{
    // This allows migration of the formerly-named VIMAccountNew [RH] (4/19/16)
    [NSKeyedUnarchiver setClass:self forClassName:@"VIMAccountNew"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
        self.tokenType = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"tokenType"];
        self.scope = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"scope"];
        self.userJSON = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"userJSON"];
        
        // Intentionally not persisting the VIMUser object [AH]
        // Intentionally not persisting the fact that a token is invalid, the next request will just re-set the flag [AH]
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [aCoder encodeObject:self.tokenType forKey:@"tokenType"];
    [aCoder encodeObject:self.scope forKey:@"scope"];
    [aCoder encodeObject:self.userJSON forKey:@"userJSON"];

    // Intentionally not persisting the VIMUser object [AH]
    // Intentionally not persisting the fact that a token is invalid, the next request will just re-set the flag [AH]
}

@end
