//
//  VIMAppConfiguration.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 10/29/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMAppConfiguration.h"

#import "VIMFacebookConfiguration.h"
#import "VIMFeaturesConfiguration.h"
#import "VIMAPIConfiguration.h"
#import "NSString+MD5.h"

@interface VIMAppConfiguration ()

@property (nonatomic, strong, readwrite) VIMFacebookConfiguration *facebookConfiguration;
@property (nonatomic, strong, readwrite) VIMFeaturesConfiguration *featuresConfiguration;
@property (nonatomic, strong, readwrite) VIMAPIConfiguration *APIConfiguration;

@property (nonatomic, strong, readwrite) NSString *keyValueHash;

@end

@implementation VIMAppConfiguration

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"facebook": @"facebookConfiguration",
             @"api": @"APIConfiguration",
             @"features": @"featuresConfiguration"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"facebook"])
        return [VIMFacebookConfiguration class];
    
    if([key isEqualToString:@"api"])
        return [VIMAPIConfiguration class];
    
    if([key isEqualToString:@"features"])
        return [VIMFeaturesConfiguration class];
    
    return nil;
}

- (void)didFinishMapping
{
    self.keyValueHash = [[NSString stringWithFormat:@"%@", self.keyValueDictionary] MD5];
}

@end
