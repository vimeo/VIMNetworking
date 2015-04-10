//
//  VIMModelObject.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 6/5/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMMappable.h"

@interface VIMModelObject : NSObject <NSCopying, NSSecureCoding, VIMMappable>

@property (nonatomic, assign) int sortOrder;
@property (nonatomic, copy) NSString *objectID;

+ (NSUInteger)modelVersion;
+ (NSDateFormatter *)dateFormatter;
+ (NSSet *)propertyKeys;

- (instancetype)initWithKeyValueDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)keyValueDictionary;

- (void)upgradeFromModelVersion:(NSUInteger)fromVersion toModelVersion:(NSUInteger)toVersion;

@end
