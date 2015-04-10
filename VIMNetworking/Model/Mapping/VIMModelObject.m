//
//  VIMModelObject.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 6/5/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

#import <objc/runtime.h>

static NSUInteger const VIMModelObjectVersion = 3;

@implementation VIMModelObject

+ (NSUInteger)modelVersion
{
	return VIMModelObjectVersion;
}

- (NSString *)objectID
{
    if(_objectID == nil || _objectID.length == 0)
        NSLog(@"%@: Accessed undefined objectID", NSStringFromClass(self.class));
	
    return _objectID;
}

+ (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    return dateFormatter;
}

#pragma mark - KeyValueDictionary creation

- (instancetype)initWithKeyValueDictionary:(NSDictionary *)dictionary
{
	self = [self init];
	if (self == nil) return nil;
    
    NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Can't initilize model object with invalid dictionary");

	for (NSString *key in dictionary)
	{
		id value = [dictionary objectForKey:key];
		
		if ([value isEqual:NSNull.null] || [value isKindOfClass:[NSNull class]])
			value = nil;
		
		[self setValue:value forKey:key];
	}
	
	return self;
}

- (NSDictionary *)keyValueDictionary
{
	return [self dictionaryWithValuesForKeys:self.class.propertyKeys.allObjects];
}

#pragma mark - VIMMappable

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
//    NSLog(@"%@: Undefined Key '%@'", NSStringFromClass(self.class), key);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	NSNumber *modelVersion = [aDecoder decodeObjectForKey:@"modelVersion"];

	if(modelVersion.unsignedIntegerValue > self.class.modelVersion)
	{
		NSLog(@"%@:initWithCoder: Could not unarchive %@. Unsupported model version %ld", NSStringFromClass(self.class), self.class, (unsigned long)modelVersion.unsignedIntegerValue);
		return nil;
	}
	
    self.objectID = [aDecoder decodeObjectForKey:@"objectID"];

	NSSet *propertyKeys = self.class.propertyKeys;
	NSMutableDictionary *KVDictionary = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
	
	for (NSString *key in propertyKeys)
	{
		id value = [aDecoder decodeObjectForKey:key];
		if (value == nil) continue;
		
		KVDictionary[key] = value;
	}
	
	self = [self initWithKeyValueDictionary:KVDictionary];
	if (self == nil)
    {
        NSLog(@"%@:initWithCoder: Could not unarchive %@", NSStringFromClass(self.class), self.class);
    }
    else
    {
        if (modelVersion.unsignedIntegerValue < self.class.modelVersion)
        {
            [self upgradeFromModelVersion:modelVersion.unsignedIntegerValue toModelVersion:self.class.modelVersion];
        }
    }
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:@(self.class.modelVersion) forKey:@"modelVersion"];

    if(_objectID && _objectID.length > 0)
        [aCoder encodeObject:self.objectID forKey:@"objectID"];
	
	[self.keyValueDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {

        if([value respondsToSelector:@selector(encodeWithCoder:)])
            [aCoder encodeObject:value forKey:key];
        
	}];
}

- (void)upgradeFromModelVersion:(NSUInteger)fromVersion toModelVersion:(NSUInteger)toVersion
{
    // Override in subclasses
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)zone
{
	return [[self.class allocWithZone:zone] initWithKeyValueDictionary:self.keyValueDictionary];
}

#pragma mark - Class Property enumeration

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block
{
	Class selfClass = self;
	BOOL stop = NO;
	
	while(!stop && ![selfClass isEqual:VIMModelObject.class])
	{
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(selfClass, &count);
		
		selfClass = selfClass.superclass;
		if(properties == NULL) continue;
		
		for(unsigned i = 0; i < count; i++)
		{
			block(properties[i], &stop);
			if (stop)
			{
                if(properties)
                {
                    free(properties);
                    properties = NULL;
                }

				break;
			}
		}

        if(properties)
        {
            free(properties);
            properties = NULL;
        }
	}
}

+ (NSSet *)propertyKeys
{
	NSSet *cachedKeys = objc_getAssociatedObject(self, @"VIMModelObject_propertyKeys");
	if (cachedKeys != nil) return cachedKeys;
	
	NSMutableSet *keys = [NSMutableSet set];
	
	[self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
		NSString *key = @(property_getName(property));
		[keys addObject:key];
	}];
	
	objc_setAssociatedObject(self, @"VIMModelObject_propertyKeys", keys, OBJC_ASSOCIATION_COPY);
	
	return keys;
}

@end
