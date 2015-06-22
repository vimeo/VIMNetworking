//
//  VIMRequestDescriptor.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/2/13.
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

#import "VIMRequestDescriptor.h"

NSString *HTTPMethodGET = @"GET";
NSString *HTTPMethodPOST = @"POST";
NSString *HTTPMethodPATCH = @"PATCH";
NSString *HTTPMethodPUT = @"PUT";
NSString *HTTPMethodDELETE = @"DELETE";

@implementation VIMRequestDescriptor

- (instancetype)init
{
	self = [super init];
	if (self)
	{
        self.descriptorID = @"";
		self.urlPath = @"";
		self.HTTPMethod = HTTPMethodGET;
		self.parameters = nil;
		self.cachePolicy = VIMCachePolicy_NetworkOnly;
		self.modelClass = nil;
		self.modelKeyPath = @"";
        self.shouldCacheResponse = YES;
        self.shouldRetryOnFailure = NO;
	}
	
	return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.descriptorID = [aDecoder decodeObjectForKey:@"descriptorID"];
        self.urlPath = [aDecoder decodeObjectForKey:@"urlPath"];
        self.HTTPMethod = [aDecoder decodeObjectForKey:@"HTTPMethod"];

        self.parameters = [aDecoder decodeObjectForKey:@"parameters"];
        self.cachePolicy = [aDecoder decodeIntegerForKey:@"cachePolicy"];
        self.shouldCacheResponse = [aDecoder decodeBoolForKey:@"shouldCacheResponse"];
        self.shouldRetryOnFailure = [aDecoder decodeBoolForKey:@"shouldRetryOnFailure"];

        self.modelClass = [aDecoder decodeObjectForKey:@"modelClass"];
        self.modelKeyPath = [aDecoder decodeObjectForKey:@"modelKeyPath"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.descriptorID forKey:@"descriptorID"];
    [aCoder encodeObject:self.urlPath forKey:@"urlPath"];
    [aCoder encodeObject:self.HTTPMethod forKey:@"HTTPMethod"];

    [aCoder encodeObject:self.parameters forKey:@"parameters"];
    [aCoder encodeInteger:self.cachePolicy forKey:@"cachePolicy"];
    [aCoder encodeBool:self.shouldCacheResponse forKey:@"shouldCacheResponse"];
    [aCoder encodeBool:self.shouldRetryOnFailure forKey:@"shouldRetryOnFailure"];

    [aCoder encodeObject:self.modelClass forKey:@"modelClass"];
    [aCoder encodeObject:self.modelKeyPath forKey:@"modelKeyPath"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    VIMRequestDescriptor *copy = [[[self class] alloc] init];
    if (copy)
    {
        copy.descriptorID = self.descriptorID;
        copy.urlPath = self.urlPath;
        copy.HTTPMethod = self.HTTPMethod;
        copy.parameters = self.parameters;
        copy.cachePolicy = self.cachePolicy;
        copy.shouldCacheResponse = self.shouldCacheResponse;
        copy.shouldRetryOnFailure = self.shouldRetryOnFailure;
        copy.modelClass = [self.modelClass copy];
        copy.modelKeyPath = self.modelKeyPath;
    }
    
    return copy;
}

@end
