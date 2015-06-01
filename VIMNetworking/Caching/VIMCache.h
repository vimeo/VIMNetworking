//
//  VIMCache.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/1/13.
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

// A thread-safe LRU cache

typedef void(^VIMCacheCompletionBlock)(id object);

@interface VIMCache : NSObject

@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, copy, readonly) NSString *basePath;

@property (nonatomic, assign) NSUInteger memoryCapacity;

+ (instancetype)sharedCache;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name basePath:(NSString *)basePath;

- (id)objectForKey:(NSString *)key; // This is a blocking method, use objectForKey:completionBlock: for better performance

- (void)objectForKey:(NSString *)key completionBlock:(VIMCacheCompletionBlock)completionBlock;

- (void)setObject:(id)object forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllObjects;
- (void)clearMemory;

- (void)setCountLimit:(NSUInteger)countLimit;
- (NSUInteger)countLimit;

@end

@interface VIMCache (Subclass)

- (NSData *)dataWithObject:(id)object;
- (id)objectWithData:(NSData *)data;
- (NSUInteger)cacheCostForObject:(id)object fromData:(NSData *)data;

@end