//
//  VIMRequestDescriptor.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/2/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
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
		self.userConnectionKey = @"";
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
        self.userConnectionKey = [aDecoder decodeObjectForKey:@"userConnectionKey"];
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
    [aCoder encodeObject:self.userConnectionKey forKey:@"userConnectionKey"];
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
        copy.userConnectionKey = self.userConnectionKey;
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
