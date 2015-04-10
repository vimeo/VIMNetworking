//
//  VIMOAuth1Authenticator.h
//  VIMCore
//
//  Created by Kashif Muhammad on 11/4/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMAccount;

@interface VIMOAuth1Authenticator : NSObject

@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *clientID;
@property (nonatomic, copy, readonly) NSString *clientSecret;

- (id)initWithURL:(NSString *)url clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret;

- (void)authenticateAccount:(VIMAccount *)account username:(NSString *)username password:(NSString *)password completionBlock:(void (^)(id responseObject, NSError *error))completionBlock;
- (void)authenticateAccount:(VIMAccount *)account parameters:(NSDictionary *)parameters completionBlock:(void (^)(id responseObject, NSError *error))completionBlock;

@end
