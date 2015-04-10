//
//  VIMRequestRetryManager.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/18/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMRequestDescriptor;
@class VIMRequestOperationManager;

@interface VIMRequestRetryManager : NSObject

- (instancetype)initWithName:(NSString *)name operationManager:(VIMRequestOperationManager *)operationManager;

- (BOOL)scheduleRetryIfNecessaryForError:(NSError *)error requestDescriptor:(VIMRequestDescriptor *)descriptor;

/*

 This class will retry requests that fail for reasons contained in errorCodes and 5XX status codes, after DefaultRetryDelayInSeconds, for numberOfRetriesPerRequest.
 
 It will not make attempts when offline, so as to not increment the retry count for a given request unecessarily.
 
 It will retry all cached requests upon initialization and upon VIMReachabilityStatusChangeOnlineNotification.

 This class is not a singleton, which means that retries will not occur when VIMReachabilityStatusChangeOnlineNotification is posted but an instance of this class does not yet exist. This is okay because presumably users will play videos often enough that init events will trigger retries frequently. 
 
 Also, avoiding singleton means that retry managers can be configured for unique circumstances (e.g. play logging vs normal likes/watchlaters). 
 
 [AH]
 
 */

@end
