//
//  VIMVimeoRequestSerializer.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 8/27/14.
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

#import "VIMJSONRequestSerializer.h"
#import "VIMHeaderProvider.h"

@implementation VIMJSONRequestSerializer

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
    
        self.writingOptions = 0;
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
