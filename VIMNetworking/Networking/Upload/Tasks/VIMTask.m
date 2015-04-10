//
//  Task.m
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMTask.h"

const NSString *VIMTaskErrorDomain = @"VIMTaskErrorDomain";

@implementation VIMTask

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _state = TaskStateNone;
    }
    
    return self;
}

- (void)resume
{
    NSAssert(NO, @"Subclasses must override.");
}

- (void)suspend
{
    NSAssert(NO, @"Subclasses must override.");
}

- (void)cancel
{
    NSAssert(NO, @"Subclasses must override.");
}

- (BOOL)didSucceed
{
    NSAssert(NO, @"Subclasses must override.");
    
    return NO;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.identifier = [coder decodeObjectForKey:@"identifier"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.error = [coder decodeObjectForKey:@"error"];
        self.state = [coder decodeIntegerForKey:@"state"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.error forKey:@"error"];
    [coder encodeInteger:self.state forKey:@"state"];
}

@end
