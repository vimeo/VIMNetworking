//
//  VIMRequestRetryManager.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/18/14.
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
