//
//  VIMAccountCredential.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/29/13.
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

#import "VIMAccountCredential.h"

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

@end
