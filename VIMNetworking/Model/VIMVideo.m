//
//  VIMVideo.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/23/13.
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

#import "VIMVideo.h"

#import "VIMUser.h"
#import "VIMPicture.h"
#import "VIMVideoFile.h"
#import "VIMConnection.h"
#import "VIMInteraction.h"
#import "VIMPictureCollection.h"
#import "VIMPrivacy.h"
#import "VIMAppeal.h"
#import "NSString+MD5.h"
#import "VIMObjectMapper.h"
#import "VIMTag.h"
#import "VIMVideoLog.h"
#import "VIMCategory.h"

@interface VIMVideo ()

@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) NSDictionary *connections;
@property (nonatomic, strong) NSDictionary *interactions;

@end

@implementation VIMVideo

- (VIMConnection *)connectionWithName:(NSString *)connectionName
{
    return [self.connections objectForKey:connectionName];
}

- (VIMInteraction *)interactionWithName:(NSString *)name
{
    return [self.interactions objectForKey:name];
}

- (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    return dateFormatter;
}

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"description": @"videoDescription",
             @"pictures": @"pictureCollection"};
}

- (Class)getClassForCollectionKey:(NSString *)key
{
    if([key isEqualToString:@"files"])
        return [VIMVideoFile class];
    
    if ([key isEqualToString:@"tags"])
        return [VIMTag class];
    
    if ([key isEqualToString:@"categories"])
        return [VIMCategory class];
    
	return nil;
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if( [key isEqualToString:@"pictures"] )
        return [VIMPictureCollection class];

    if([key isEqualToString:@"user"])
        return [VIMUser class];

	if([key isEqualToString:@"metadata"])
        return [NSMutableDictionary class];

    if([key isEqualToString:@"privacy"])
        return [VIMPrivacy class];
    
    if([key isEqualToString:@"appeal"])
        return [VIMAppeal class];
    
    if( [key isEqualToString:@"log"] )
        return [VIMVideoLog class];

    return nil;
}

- (void)didFinishMapping
{
    self.objectID = [self.uri MD5];
    
    if ([self.pictureCollection isEqual:[NSNull null]])
    {
        self.pictureCollection = nil;
    }

    // This is a temporary fix until we implement model versioning for cached JSON [AH]
    [self checkIntegrityOfPictureCollection];

    [self parseConnections];
    [self parseInteractions];
    [self formatCreatedTime];
    [self formatModifiedTime];
    
    id ob = [self.stats valueForKey:@"plays"];
    if (ob && [ob isKindOfClass:[NSNumber class]])
    {
        self.numPlays = ob;
    }
}

#pragma mark - Model Versioning

// This is only called for unarchived model objects [AH]

- (void)upgradeFromModelVersion:(NSUInteger)fromVersion toModelVersion:(NSUInteger)toVersion
{
    if (fromVersion == 2 && toVersion == 3)
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
                if([connection respondsToSelector:@selector(didFinishMapping)])
                    [connection didFinishMapping];
                
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

- (void)formatCreatedTime
{
    if ([self.createdTime isKindOfClass:[NSString class]])
    {
        self.createdTime = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.createdTime];
    }
}

- (void)formatModifiedTime
{
    if ([self.modifiedTime isKindOfClass:[NSString class]])
    {
        self.modifiedTime = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.modifiedTime];
    }
}

# pragma mark - Helpers

- (BOOL)canViewInfo
{
    return NO;
}

- (BOOL)canComment
{
    NSString *privacy = self.privacy.comments;
    if( [privacy isEqualToString:VIMPrivacy_Public] )
    {
        return YES;
    }
    else if( [privacy isEqualToString:VIMPrivacy_Private] )
    {
        return NO;
    }
    else
    {
        VIMConnection *connection = [self connectionWithName:VIMConnectionNameComments];
        return (connection && [connection canPost]);
    }
}

- (BOOL)canViewComments
{
    return [self connectionWithName:VIMConnectionNameComments].uri != nil;
}

- (BOOL)isVOD
{
    NSString *privacy = self.privacy.view;
    return [privacy isEqualToString:VIMPrivacy_VOD];
}

- (BOOL)isPrivate
{
    NSString *privacy = self.privacy.view;
    return ![privacy isEqualToString:VIMPrivacy_Public] && ![privacy isEqualToString:VIMPrivacy_VOD];
}

- (BOOL)isAvailable
{
    return [self.status isEqualToString:@"available"];
}

@end
