//
//  VIMCache.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/1/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
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