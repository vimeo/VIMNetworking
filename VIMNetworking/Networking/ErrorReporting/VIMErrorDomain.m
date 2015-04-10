//
//  VIMErrorDomain.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/16/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMErrorDomain.h"
#import "VIMUploadErrorDomain.h"

static NSMutableDictionary *errorTypesDictionary;

@implementation VIMErrorDomain

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errorTypesDictionary = [NSMutableDictionary new];
    });
    [VIMUploadErrorDomain loadErrorTypeDictionary];
}

+ (void)loadErrorTypeDictionary
{
    NSString *domainName = [self domainName];
    NSArray *errorTypes = [self errorTypes];
    if ( domainName == nil || errorTypes == nil )
    {
        return;
    }
    
    [errorTypesDictionary setObject:errorTypes forKey:domainName];
}

+ (NSString *)domainName
{
    return nil;
}

+ (NSArray *)errorTypes
{
    return nil;
}

+ (NSString *)errorTypeForDomainName:(NSString *)domainName errorCode:(NSInteger)errorCode
{
    return [[errorTypesDictionary objectForKey:domainName] objectAtIndex:errorCode];
}

+ (NSString *)errorDomainForErrorType:(NSString *)errorType
{
    for ( NSString *key in [errorTypesDictionary allKeys] )
    {
        NSArray *errorTypeArray = [errorTypesDictionary objectForKey:key];
        if ( [errorTypeArray containsObject:errorType] )
        {
            return key;
        }
    }
    return nil;
}

@end
