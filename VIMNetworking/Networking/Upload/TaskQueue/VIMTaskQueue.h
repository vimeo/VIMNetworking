//
//  UploadQueue.h
//  Pegasus
//
//  Created by Hanssen, Alfie on 2/13/15.
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

@class VIMTask;

@interface VIMTaskQueue : NSObject

@property (nonatomic, strong, readonly) NSString *name;

@property (nonatomic, assign, readonly) NSInteger taskCount;

- (instancetype)initWithName:(NSString *)name;

- (void)addTasks:(NSArray *)tasks;
- (void)addTask:(VIMTask *)task;
- (void)cancelAllTasks;
- (void)cancelTask:(VIMTask *)task;
- (void)suspend;
- (void)resume;
- (BOOL)isSuspended;

// Optional subclass overrides

// Override to modiy task before it is started [AH]
- (void)prepareTask:(VIMTask *)task;

- (VIMTask *)taskForIdentifier:(NSString *)identifier;

// Override to return shared container defaults [AH]
- (NSUserDefaults *)taskQueueDefaults; // TODO: set this as a property instead? [AH]

@end
