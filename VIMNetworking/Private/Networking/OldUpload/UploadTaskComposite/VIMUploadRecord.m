//
//  VIMUploadRecord.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 12/9/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMUploadRecord.h"

@interface VIMUploadRecord () <NSCoding>

@end

@implementation VIMUploadRecord

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.completeURI = [aDecoder decodeObjectForKey:@"completeURI"];
        self.uploadURISecure = [aDecoder decodeObjectForKey:@"uploadURISecure"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.completeURI forKey:@"completeURI"];
    [aCoder encodeObject:self.uploadURISecure forKey:@"uploadURISecure"];
}

@end
