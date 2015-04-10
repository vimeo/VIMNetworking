//
//  VideoMetadata.m
//  Hermes
//
//  Created by Hanssen, Alfie on 3/5/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
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
        self.videoTitle = [coder decodeObjectForKey:@"videoTitle"];
        self.videoDescription = [coder decodeObjectForKey:@"videoDescription"];
        self.videoPrivacy = [coder decodeObjectForKey:@"videoPrivacy"];
        self.tags = [coder decodeObjectForKey:@"tags"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.videoTitle forKey:@"videoTitle"];
    [coder encodeObject:self.videoDescription forKey:@"videoDescription"];
    [coder encodeObject:self.videoPrivacy forKey:@"videoPrivacy"];
    [coder encodeObject:self.tags forKey:@"tags"];
}

@end
