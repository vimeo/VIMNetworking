//
//  VIMUser.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/4/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMUser.h"
#import "VIMConnection.h"
#import "VIMInteraction.h"
#import "VIMPictureCollection.h"
#import "VIMPicture.h"
#import "VIMObjectMapper.h"
#import "NSString+MD5.h"
#import "VIMSession.h"

@interface VIMUser ()

@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) NSDictionary *connections;
@property (nonatomic, strong) NSDictionary *interactions;

@property (nonatomic, copy) NSString *account;
@property (nonatomic, assign, readwrite) VIMUserAccountType accountType;

@end

@implementation VIMUser

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
    if( [key isEqualToString:@"pictures"] )
        return [VIMPictureCollection class];
    
    return nil;
}

- (void)didFinishMapping
{
    self.objectID = [self.uri MD5];

    if ([self.pictureCollection isEqual:[NSNull null]])
    {
        self.pictureCollection = nil;
    }

    // This is a temporary fix until we implement (1) ability to refresh authenticated user cache, and (2) model versioning for cached JSON [AH]
    [self checkIntegrityOfPictureCollection];
    
    [self parseConnections];
    [self parseInteractions];
    [self parseAccountType];
    [self formatCreatedTime];
}

#pragma mark - Parsing Helpers

- (void)parseConnections
{
    NSMutableDictionary *connections = [NSMutableDictionary dictionary];
    
    NSDictionary *dict = [self.metadata valueForKey:@"connections"];
    if([dict isKindOfClass:[NSDictionary class]])
    {
        for(NSString *key in [dict allKeys])
        {
            NSDictionary *value = [dict valueForKey:key];
            if([value isKindOfClass:[NSDictionary class]])
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
    if([dict isKindOfClass:[NSDictionary class]])
    {
        for(NSString *key in [dict allKeys])
        {
            NSDictionary *value = [dict valueForKey:key];
            if([value isKindOfClass:[NSDictionary class]])
            {
                VIMInteraction *interaction = [[VIMInteraction alloc] initWithKeyValueDictionary:value];
                if([interaction respondsToSelector:@selector(didFinishMapping)])
                    [interaction didFinishMapping];
                
                [interactions setObject:interaction forKey:key];
            }
        }
    }
    
    self.interactions = interactions;
}

- (void)parseAccountType
{
    if ([self.account isEqualToString:@"plus"])
    {
        self.accountType = VIMUserAccountTypePlus;
    }
    else if ([self.account isEqualToString:@"pro"])
    {
        self.accountType = VIMUserAccountTypePro;
    }
    else if ([self.account isEqualToString:@"basic"])
    {
        self.accountType = VIMUserAccountTypeBasic;
    }
}

- (void)formatCreatedTime
{
    if ([self.createdTime isKindOfClass:[NSString class]])
    {
        self.createdTime = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.createdTime];
    }
}

#pragma mark - Helpers

- (BOOL)hasCopyrightMatch
{
    VIMConnection *connection = [self connectionWithName:VIMConnectionNameViolations];
    return (connection && connection.total.intValue > 0);
}

- (BOOL)isFollowing
{
    VIMInteraction *interaction = [self interactionWithName:VIMInteractionNameFollow];
    return (interaction && interaction.added.boolValue);
}

#pragma mark - Model Versioning

// This is only called for unarchived model objects [AH]

- (void)upgradeFromModelVersion:(NSUInteger)fromVersion toModelVersion:(NSUInteger)toVersion
{
    if ((fromVersion == 1 && toVersion == 2) || (fromVersion == 2 && toVersion == 3))
    {
        [self checkIntegrityOfPictureCollection];
    }
}

- (void)checkIntegrityOfPictureCollection
{
    if ([self.pictureCollection isKindOfClass:[NSArray class]])
    {
        NSArray *pictures = (NSArray *)self.pictureCollection;
        self.pictureCollection = [VIMPictureCollection new];
        
        if ([pictures count])
        {
            if ([[pictures firstObject] isKindOfClass:[VIMPicture class]])
            {
                self.pictureCollection.pictures = pictures;
            }
            else if ([[pictures firstObject] isKindOfClass:[NSDictionary class]])
            {
                NSMutableArray *pictureObjects = [NSMutableArray array];
                for (NSDictionary *dictionary in pictures)
                {
                    VIMPicture *picture = [[VIMPicture alloc] initWithKeyValueDictionary:dictionary];
                    [pictureObjects addObject:picture];
                }

                self.pictureCollection.pictures = pictureObjects;
            }
        }
    }
}

@end
