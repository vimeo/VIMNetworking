//
//  Task.h
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

#import <Foundation/Foundation.h>

extern const NSString * __nonnull VIMTaskErrorDomain;

typedef NS_ENUM(NSInteger, VIMTaskState)
{
    TaskStateNone,
    TaskStateExecuting,
    TaskStateSuspended,
    TaskStateCancelled,
    TaskStateFinished
};

@class VIMTask;

@protocol VIMTaskDelegate <NSObject>

@optional
- (void)taskDidStart:(nonnull VIMTask *)task;
- (void)task:(nonnull VIMTask *)task didStartSubtask:(nonnull VIMTask *)subtask;
- (void)task:(nonnull VIMTask *)task didCompleteSubtask:(nonnull VIMTask *)subtask;

@required
- (void)taskDidComplete:(nonnull VIMTask *)task;

@end

@interface VIMTask : NSObject <NSCoding>

@property (nonatomic, weak, nullable) id<VIMTaskDelegate> delegate;

@property (nonatomic, strong, nullable) NSString *identifier;
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, assign) VIMTaskState state;

- (void)resume;
- (void)suspend;
- (void)cancel;
- (BOOL)didSucceed;

@end
