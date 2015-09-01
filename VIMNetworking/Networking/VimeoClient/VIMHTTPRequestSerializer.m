//
//  VIMHTTPRequestSerializer.m
//  Pods
//
//  Created by Hanssen, Alfie on 9/1/15.
//
//

#import "VIMHTTPRequestSerializer.h"

@implementation VIMHTTPRequestSerializer

#pragma mark - Overrides

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizationHeaderValue:)])
    {
        NSString *value = [self.delegate authorizationHeaderValue:self];
        [request setValue:value forHTTPHeaderField:@"Authorization"];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(acceptHeaderValue:)])
    {
        NSString *value = [self.delegate acceptHeaderValue:self];
        [request setValue:value forHTTPHeaderField:@"Accept"];
    }
    
    return request;
}

@end
