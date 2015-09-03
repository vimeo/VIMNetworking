//
//  VIMHTTPRequestSerializer.m
//  VIMUpload
//
//  Created by Hanssen, Alfie on 9/1/15.
//
//

#import "VIMHTTPRequestSerializer.h"
#import "VIMHeaderProvider.h"

@implementation VIMHTTPRequestSerializer

- (instancetype)initWithAPIVersionString:(NSString *)APIVersionString
{
    NSParameterAssert(APIVersionString);
    
    self = [self init];
    if (self)
    {
        NSString *acceptHeaderValue = [VIMHeaderProvider acceptHeaderValueWithAPIVersionString:APIVersionString];
        [self setValue:acceptHeaderValue forHTTPHeaderField:AcceptHeaderKey];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSString *acceptHeaderValue = [VIMHeaderProvider defaultAcceptHeaderValue];
        [self setValue:acceptHeaderValue forHTTPHeaderField:AcceptHeaderKey];
        
        NSString *userAgent = [VIMHeaderProvider defaultUserAgentString];
        if (userAgent)
        {
            [self setValue:userAgent forHTTPHeaderField:UserAgentHeaderKey];
        }
    }
    
    return self;
}

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
        [request setValue:value forHTTPHeaderField:AuthorizationHeaderKey];
    }
    
    return request;
}

@end
