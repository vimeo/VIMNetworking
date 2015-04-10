//
//  VIMRequestDescriptor.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/2/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
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
