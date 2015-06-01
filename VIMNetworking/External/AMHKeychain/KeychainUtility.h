//
//  KeychainUtility.h
//
//  Created by Alfie Hanssen on 3/1/13.
//
//

#import <Security/Security.h>

@interface KeychainUtility : NSObject

+ (void)configureWithService:(NSString *)service accessGroup:(NSString *)accessGroup; // Optional configuration
+ (instancetype)sharedInstance;

- (BOOL)setData:(NSData *)data forAccount:(NSString *)account;
- (NSData *)dataForAccount:(NSString *)account;
- (BOOL)deleteDataForAccount:(NSString *)account;

@end
