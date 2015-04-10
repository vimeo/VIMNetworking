//
//  AAA.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 3/6/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMAccountManager.h"

@interface VIMAccountManager (Private)

- (NSOperation *)joinWithDisplayName:(NSString *)displayName email:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock;

- (NSOperation *)loginWithEmail:(NSString *)email password:(NSString *)password completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock;

- (NSOperation *)joinWithFacebookToken:(NSString *)facebookToken completionBlock:(VIMAccountManagerErrorCompletionBlock)completionBlock;

- (NSOperation *)loginWithFacebookToken:(NSString *)facebookToken completionBlock:(void (^)(BOOL associatedVimeoAccountExists, NSError *error))completionBlock;

@end
