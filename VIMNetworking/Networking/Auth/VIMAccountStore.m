//
//  VIMAccountStore.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
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

#import "VIMAccountStore.h"
#import "VIMAccount.h"
#import "VIMKeychain.h"
#import "VIMAccount.h"
#import "VIMAccountCredential.h"
#import "VIMObjectMapper.h"
#import "VIMUser.h"

@implementation VIMAccountStore

#pragma mark - VIMAccountStoreProtocol

+ (VIMAccount *)loadAccountForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    if (key == nil)
    {
        return nil;
    }
    
    VIMAccount *account = nil;
    
    NSData *data = [[VIMKeychain sharedInstance] dataForAccount:key];
    if (data)
    {
        NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        @try
        {
            account = [keyedUnarchiver decodeObject];
            
            if (account.userJSON)
            {
                VIMObjectMapper *mapper = [[VIMObjectMapper alloc] init];
                [mapper addMappingClass:[VIMUser class] forKeypath:@""];
                VIMUser *user = [mapper applyMappingToJSON:account.userJSON];
                
                account.user = user;
            }
        }
        @catch (NSException *exception)
        {
            NSLog(@"VIMAccountStore: An exception occured on load: %@", exception);
            
            BOOL success = [[VIMKeychain sharedInstance] deleteDataForAccount:key];
            if (!success)
            {
                NSLog(@"Unable to delete data for account key: %@", key);
            }
        }
        
        [keyedUnarchiver finishDecoding];
    }

    return account;
}

// TODO: should we not be saving the user object? [AH]

+ (BOOL)saveAccount:(VIMAccount *)account forKey:(NSString *)key
{
    NSParameterAssert(key);
    NSParameterAssert(account);
    
    if (account == nil || key == nil)
    {
        return NO;
    }
    
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [keyedArchiver encodeObject:account];
    [keyedArchiver finishEncoding];
    
    return [[VIMKeychain sharedInstance] setData:data forAccount:key];
}

+ (BOOL)deleteAccountForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    if (key == nil)
    {
        return NO;
    }

    return [[VIMKeychain sharedInstance] deleteDataForAccount:key];
}

@end
