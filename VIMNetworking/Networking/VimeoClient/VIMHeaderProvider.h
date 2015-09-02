//
//  VIMHeaderProvider.h
//  Pods
//
//  Created by Hanssen, Alfie on 9/2/15.
//
//

#import <Foundation/Foundation.h>

extern NSString *const __nonnull DefaultAPIVersionString;
extern NSString *const __nonnull AcceptHeaderKey;
extern NSString *const __nonnull UserAgentHeaderKey;
extern NSString *const __nonnull AuthorizationHeaderKey;

@interface VIMHeaderProvider : NSObject

+ (nonnull NSString *)defaultUserAgentString;
+ (nonnull NSString *)defaultAcceptHeaderValue;
+ (nonnull NSString *)acceptHeaderValueWithAPIVersionString:(nonnull NSString *)APIVersionString;

@end
