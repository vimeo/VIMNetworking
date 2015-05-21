//
//  VIMCategory.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/20/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMCategory.h"
#import "VIMPictureCollection.h"
#import "NSString+MD5.h"
#import "VIMConnection.h"
#import "VIMInteraction.h"

@interface VIMCategory ()

@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) NSDictionary *connections;
@property (nonatomic, strong) NSDictionary *interactions;

@property (nonatomic, strong) NSNumber *topLevel;

@end

@implementation VIMCategory

#pragma mark - Public API

- (VIMConnection *)connectionWithName:(NSString *)connectionName
{
    return [self.connections objectForKey:connectionName];
}

- (VIMInteraction *)interactionWithName:(NSString *)name
{
    return [self.interactions objectForKey:name];
}

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"pictures": @"pictureCollection"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"pictures"])
    {
        return [VIMPictureCollection class];
    }
    
    return nil;
}

- (void)didFinishMapping
{
    self.objectID = [self.uri MD5];
    
    if (self.topLevel && [self.topLevel isKindOfClass:[NSNumber class]])
    {
        self.isTopLevel = [self.topLevel boolValue];
    }
    
    [self parseConnections];
    [self parseInteractions];
}

#pragma mark - Parsing Helpers

- (void)parseConnections
{
    NSMutableDictionary *connections = [NSMutableDictionary dictionary];
    
    NSDictionary *dict = [self.metadata valueForKey:@"connections"];
    if ([dict isKindOfClass:[NSDictionary class]])
    {
        for (NSString *key in [dict allKeys])
        {
            NSDictionary *value = [dict valueForKey:key];
            if ([value isKindOfClass:[NSDictionary class]])
            {
                VIMConnection *connection = [[VIMConnection alloc] initWithKeyValueDictionary:value];
                [connections setObject:connection forKey:key];
            }
        }
    }
    
    self.connections = connections;
}

- (void)parseInteractions
{
    NSMutableDictionary *interactions = [NSMutableDictionary dictionary];
    
    NSDictionary *dict = [self.metadata valueForKey:@"interactions"];
    if ([dict isKindOfClass:[NSDictionary class]])
    {
        for (NSString *key in [dict allKeys])
        {
            NSDictionary *value = [dict valueForKey:key];
            if ([value isKindOfClass:[NSDictionary class]])
            {
                VIMInteraction *interaction = [[VIMInteraction alloc] initWithKeyValueDictionary:value];
                if ([interaction respondsToSelector:@selector(didFinishMapping)])
                {
                    [interaction didFinishMapping];
                }
                
                [interactions setObject:interaction forKey:key];
            }
        }
    }
    
    self.interactions = interactions;
}

@end
