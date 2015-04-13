//
//  VIMErrorDomain.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 7/16/14.
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
