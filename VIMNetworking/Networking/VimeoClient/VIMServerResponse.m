//
//  VIMServerResponse.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 5/1/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMServerResponse.h"

@implementation VIMServerResponse

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.result = [aDecoder decodeObjectForKey:@"result"];

        self.totalResults = [[aDecoder decodeObjectForKey:@"totalResults"] intValue];
        self.totalPages = [[aDecoder decodeObjectForKey:@"totalPages"] intValue];
        self.currentPage = [[aDecoder decodeObjectForKey:@"currentPage"] intValue];
        self.resultsPerPage = [[aDecoder decodeObjectForKey:@"resultsPerPage"] intValue];

        self.first = [aDecoder decodeObjectForKey:@"first"];
        self.last = [aDecoder decodeObjectForKey:@"last"];
        self.next = [aDecoder decodeObjectForKey:@"next"];
        self.previous = [aDecoder decodeObjectForKey:@"previous"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if(self.result && [self.result respondsToSelector:@selector(encodeWithCoder:)])
        [aCoder encodeObject:self.result forKey:@"result"];

    [aCoder encodeObject:[NSNumber numberWithInt:self.totalResults] forKey:@"totalResults"];
    [aCoder encodeObject:[NSNumber numberWithInt:self.totalPages] forKey:@"totalPages"];
    [aCoder encodeObject:[NSNumber numberWithInt:self.currentPage] forKey:@"currentPage"];
    [aCoder encodeObject:[NSNumber numberWithInt:self.resultsPerPage] forKey:@"resultsPerPage"];

    [aCoder encodeObject:self.first forKey:@"first"];
    [aCoder encodeObject:self.last forKey:@"last"];
    [aCoder encodeObject:self.next forKey:@"next"];
    [aCoder encodeObject:self.previous forKey:@"previous"];
}

@end
