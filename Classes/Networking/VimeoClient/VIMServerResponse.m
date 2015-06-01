//
//  VIMServerResponse.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 5/1/13.
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
