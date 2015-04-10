//
//  VIMTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/26/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMTaskOld.h"

@implementation VIMTaskOld

- (id)init
{
	self = [super init];
	if (self)
	{
        _dateCreated = [NSDate date];
		_status = VIMTaskStatus_Waiting;
		_progress = 0.0f;
        _taskID = [[NSProcessInfo processInfo] globallyUniqueString];
	}
	
	return self;
}

- (void)start
{
    NSAssert(NO, @"VIMTask start must be implemented by inheriting class");
}

- (void)stop
{
    if(self.operation)
    {
        [self.operation cancel];
    }
}

- (void)cancel
{
    if(self.operation)
    {
        [self.operation cancel];
    }
    
    self.isCancelled = YES;
    self.status = VIMTaskStatus_Finished;
}

- (void)pause
{
    self.isPaused = YES;
}

- (void)resume
{
    self.isPaused = NO;
}

- (void)prepareForRetry
{
    if(self.status == VIMTaskStatus_Finished)
    {
        if(self.error || self.isCancelled)
        {
            self.error = nil;
            self.isCancelled = NO;
            self.status = VIMTaskStatus_Waiting;
        }
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.dateCreated = [aDecoder decodeObjectForKey:@"dateCreated"];
        self.status = [aDecoder decodeIntForKey:@"status"];
        self.progress = [aDecoder decodeFloatForKey:@"progress"];
        self.error = [aDecoder decodeObjectForKey:@"error"];
        self.isCancelled = [aDecoder decodeBoolForKey:@"isCancelled"];
        self.isPaused = [aDecoder decodeBoolForKey:@"isPaused"];
        self.taskID = [aDecoder decodeObjectForKey:@"taskID"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dateCreated forKey:@"dateCreated"];
    [aCoder encodeInt:self.status forKey:@"status"];
    [aCoder encodeFloat:self.progress forKey:@"progress"];
    [aCoder encodeObject:self.error forKey:@"error"];
    [aCoder encodeBool:self.isCancelled forKey:@"isCancelled"];
    [aCoder encodeBool:self.isPaused forKey:@"isPaused"];
    [aCoder encodeObject:self.taskID forKey:@"taskID"];
}

@end
