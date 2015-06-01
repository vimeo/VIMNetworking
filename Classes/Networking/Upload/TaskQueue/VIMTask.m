//
//  Task.m
//  Pegasus
//
//  Created by Alfred Hanssen on 2/27/15.
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
        self.identifier = [coder decodeObjectForKey:NSStringFromSelector(@selector(identifier))];
        self.name = [coder decodeObjectForKey:NSStringFromSelector(@selector(name))];
        self.error = [coder decodeObjectForKey:NSStringFromSelector(@selector(error))];
        self.state = [coder decodeIntegerForKey:NSStringFromSelector(@selector(state))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.identifier forKey:NSStringFromSelector(@selector(identifier))];
    [coder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
    [coder encodeInteger:self.state forKey:NSStringFromSelector(@selector(state))];
}

@end
