//
//  VIMRequestDescriptor.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/2/13.
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

typedef NS_ENUM(NSInteger, VIMCachePolicy)
{
    VIMCachePolicy_NetworkOnly = 0,			// Only get result from network
	VIMCachePolicy_LocalOnly,				// Only get result from cache
	VIMCachePolicy_TryNetworkFirst,			// First try to fetch from network, if failed then return local result
	VIMCachePolicy_LocalAndNetwork,         // Both results will be returned. First from local cache and then from network
};

extern NSString *HTTPMethodGET;
extern NSString *HTTPMethodPOST;
extern NSString *HTTPMethodPATCH;
extern NSString *HTTPMethodPUT;
extern NSString *HTTPMethodDELETE;

@interface VIMRequestDescriptor : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, copy) NSString *descriptorID;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, copy) NSString *userConnectionKey;
@property (nonatomic, copy) NSString *HTTPMethod;

@property (nonatomic, strong) id parameters;
@property (nonatomic, assign) VIMCachePolicy cachePolicy;
@property (nonatomic, assign) BOOL shouldCacheResponse;
@property (nonatomic, assign) BOOL shouldRetryOnFailure;

@property (nonatomic) Class modelClass;
@property (nonatomic, copy) NSString *modelKeyPath;

@end
