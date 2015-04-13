//
//  VideoMetadata.m
//  Pegasus
//
//  Created by Hanssen, Alfie on 3/5/15.
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

#import "VIMVideoMetadata.h"

@interface VIMVideoMetadata () <NSCoding>

@end

@implementation VIMVideoMetadata

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.videoTitle = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoTitle))];
        self.videoDescription = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoDescription))];
        self.videoPrivacy = [coder decodeObjectForKey:NSStringFromSelector(@selector(videoPrivacy))];
        self.tags = [coder decodeObjectForKey:NSStringFromSelector(@selector(tags))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.videoTitle forKey:NSStringFromSelector(@selector(videoTitle))];
    [coder encodeObject:self.videoDescription forKey:NSStringFromSelector(@selector(videoDescription))];
    [coder encodeObject:self.videoPrivacy forKey:NSStringFromSelector(@selector(videoPrivacy))];
    [coder encodeObject:self.tags forKey:NSStringFromSelector(@selector(tags))];
}

@end
