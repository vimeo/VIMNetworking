//
//  KeychainUtility.h
//
//  Created by Alfie Hanssen on 3/1/13.
//
//

#import <Security/Security.h>
#import <Foundation/Foundation.h>

@interface KeychainUtility : NSObject

+ (void)configureWithService:(nonnull NSString *)service accessGroup:(nullable NSString *)accessGroup; // Optional configuration

+ (nullable instancetype)sharedInstance;

- (BOOL)setData:(nonnull NSData *)data forAccount:(nonnull NSString *)account;
- (nullable NSData *)dataForAccount:(nonnull NSString *)account;
- (BOOL)deleteDataForAccount:(nonnull NSString *)account;

@end
