//
//  VIMVimeoClient.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/24/13.
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

#import "VIMRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "VIMMappable.h"
#import "VIMObjectMapper.h"
#import "VIMCache.h"
#import "VIMRequestToken.h"
#import "VIMRequestOperation.h"
#import "VIMServerResponseMapper.h"
#import "NSError+BaseError.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"

NSString * const kVimeoClientErrorDomain = @"VimeoClientErrorDomain";

@interface VIMRequestOperationManager ()
{
    dispatch_queue_t _responseQueue;
}

@end

@implementation VIMRequestOperationManager

- (void)dealloc
{
    [self cancelAllRequests];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    NSParameterAssert(url);

    self = [super initWithBaseURL:url];
    if(self)
    {
        // TODO: Do we need both queues or will one suffice? [AH]
		
        _responseQueue = dispatch_queue_create("com.vimeo.VIMClient.completionQueue", DISPATCH_QUEUE_SERIAL);

        self.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        self.requestSerializer = [VIMRequestSerializer serializer];
        self.responseSerializer = [VIMResponseSerializer serializer];

#if (defined(ADHOC) || defined(RELEASE))
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        self.securityPolicy.allowInvalidCertificates = NO;
        self.securityPolicy.validatesCertificateChain = NO;
        self.securityPolicy.validatesDomainName = YES;
#endif
    }
    
    return self;
}

#pragma mark - Cancellation

- (void)cancelRequest:(id<VIMRequestToken>)request
{
    NSParameterAssert(request);

    if ([request isKindOfClass:[VIMRequestOperation class]])
    {
        VIMRequestOperation *operation = (VIMRequestOperation *)request;

        [operation cancel];
    }
}

- (void)cancelAllRequestsForHandler:(id)handler
{
    NSParameterAssert(handler);
    
    if (handler == nil)
    {
        return;
    }
    
    for (NSOperation *operation in [self.operationQueue operations])
    {
        if ([operation isKindOfClass:[VIMRequestOperation class]])
        {
            if (((VIMRequestOperation *)operation).handler == handler)
            {
                [operation cancel];
            }
        }
    }
}

- (void)cancelAllRequests
{
    [self.operationQueue cancelAllOperations];
}

#pragma mark - Requests

- (id<VIMRequestToken>)requestDescriptor:(VIMRequestDescriptor *)descriptor
                                  completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    return [self requestDescriptor:descriptor handler:self completionBlock:completionBlock];
}

// TODO: This method needs some serious attention [AH]

- (id<VIMRequestToken>)requestDescriptor:(VIMRequestDescriptor *)descriptor
                                          handler:(id)handler
                                  completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    NSParameterAssert(descriptor);
    NSParameterAssert([descriptor.urlPath length]);
    NSAssert([descriptor.parameters isKindOfClass:[NSArray class]] ||
             [descriptor.parameters isKindOfClass:[NSDictionary class]] || descriptor.parameters == nil, @"Invalid parameters");
    
    if (self.cache == nil && (descriptor.cachePolicy == VIMCachePolicy_LocalOnly || descriptor.cachePolicy == VIMCachePolicy_LocalAndNetwork))
    {
        dispatch_async(_responseQueue, ^{

            if (completionBlock)
            {
                NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"cannot fetch from cache when cache is nil"}];
                completionBlock(nil, error);
            }
        
        });
        
        return nil;
    }

    descriptor.parameters = [self cleanParameters:descriptor.parameters];
    
    NSString *fullURLString = [[NSURL URLWithString:descriptor.urlPath relativeToURL:self.baseURL] absoluteString];
    NSError *error = nil;
        
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:descriptor.HTTPMethod URLString:fullURLString parameters:descriptor.parameters error:&error];
    
    if (error)
    {
        dispatch_async(_responseQueue, ^{

            if (completionBlock)
            {
                completionBlock(nil, error);
            }

        });
                       
        return nil;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizationHeaderValue:)])
    {
        NSString *value = [self.delegate authorizationHeaderValue:self];
        
        [request setValue:value forHTTPHeaderField:@"Authorization"];
    }
    
    if (self.cache && (descriptor.cachePolicy == VIMCachePolicy_LocalOnly || descriptor.cachePolicy == VIMCachePolicy_LocalAndNetwork))
    {
        CFTimeInterval startTime = CACurrentMediaTime();
        NSLog(@"cache start (%@)", descriptor.urlPath);
        
        VIMRequestOperation *operation = [[VIMRequestOperation alloc] initWithRequest:request];
        operation.descriptor = descriptor;
        operation.handler = handler;
        
        // try to fetch from cache
        [self.cache objectForKey:request.URL.absoluteString completionBlock:^(id JSON) {

            if ([operation isCancelled])
            {
                return;
            }

            dispatch_async(_responseQueue, ^{

                if ([operation isCancelled])
                {
                    return;
                }

                if (JSON == nil)
                {
                    CFTimeInterval endTime = CACurrentMediaTime();
                    NSLog(@"cache failure %g sec (%@)", endTime - startTime, descriptor.urlPath);
                    
                    VIMServerResponse *response = [[VIMServerResponse alloc] init];
                    response.request = operation;
                    response.isCachedResponse = YES;
                    response.isFinalResponse = descriptor.cachePolicy == VIMCachePolicy_LocalOnly;
                    
                    if (completionBlock)
                    {
                        NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"no cached response found"}];
                        completionBlock(response, error);
                    }
                    
                    return;
                }

                [VIMServerResponseMapper responseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {

                    CFTimeInterval endTime = CACurrentMediaTime();
                    NSLog(@"cache success %g sec (%@)", endTime - startTime, descriptor.urlPath);
                    
                    if (response)
                    {
                        response.isCachedResponse = YES;
                        response.isFinalResponse = descriptor.cachePolicy == VIMCachePolicy_LocalOnly;
                    }
                    
                    if (completionBlock)
                    {
                        completionBlock(response, error);
                    }

                }];

            });

        }];
        
        if (descriptor.cachePolicy == VIMCachePolicy_LocalOnly)
        {
            return operation;
        }
    }
    
    CFTimeInterval startTime = CACurrentMediaTime();
    NSLog(@"server start (%@)", descriptor.urlPath);
    
    VIMRequestOperation *operation = [self VIMRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *HTTPOperation, id JSON) {
        
        VIMRequestOperation *operation = (VIMRequestOperation *)HTTPOperation;
        
        if ([operation isCancelled])
        {
            return;
        }
        
        if (self.cache && descriptor.shouldCacheResponse)
        {
            [self.cache setObject:JSON forKey:request.URL.absoluteString];
        }
        
        dispatch_async(_responseQueue, ^{

            [VIMServerResponseMapper responseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
                
                CFTimeInterval endTime = CACurrentMediaTime();
                NSLog(@"server success %g sec (%@)", endTime - startTime, descriptor.urlPath);

                if (response)
                {
                    response.isFinalResponse = YES;
                }
                
                if (completionBlock)
                {
                    completionBlock(response, error);
                }

            }];

        });
        
    } failure:^(AFHTTPRequestOperation *HTTPOperation, NSError *error) {
        
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"server failure %g sec (%@)", endTime - startTime, descriptor.urlPath);

        VIMRequestOperation *operation = (VIMRequestOperation *)HTTPOperation;
        if ([operation isCancelled])
        {
            return;
        }

        dispatch_async(_responseQueue, ^{

            VIMServerResponse *response = [[VIMServerResponse alloc] init];
            response.request = operation;
            response.urlResponse = operation.response;
            response.isCachedResponse = NO;
            response.isFinalResponse = descriptor.cachePolicy != VIMCachePolicy_TryNetworkFirst;
            
            NSError *parsedError = [self _parseServerError:error]; // Why is this necessary? [AH]
            if (parsedError)
            {
                if (completionBlock)
                {
                    completionBlock(response, parsedError);
                }
            }
            else if (error)
            {
                if (completionBlock)
                {
                    completionBlock(response, error);
                }
            }
            
            if (self.cache && descriptor.cachePolicy == VIMCachePolicy_TryNetworkFirst)
            {
                NSLog(@"fetchWithRequestDescriptor: Fetch from network failed. Trying to fetch from cache");
                
                [self.cache objectForKey:request.URL.absoluteString completionBlock:^(id JSON) {

                    dispatch_async(_responseQueue, ^{

                        if (JSON == nil)
                        {
                            VIMServerResponse *response = [[VIMServerResponse alloc] init];
                            response.request = operation;
                            response.isCachedResponse = YES;
                            response.isFinalResponse = YES;
                            
                            if (completionBlock)
                            {
                                NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"no cached response found"}];
                                completionBlock(response, error);
                            }
                            
                            return;
                        }

                        [VIMServerResponseMapper responseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
                            
                            if (response)
                            {
                                response.isCachedResponse = YES;
                                response.isFinalResponse = YES;
                            }
                            
                            if (completionBlock)
                            {
                                completionBlock(response, error);
                            }
                            
                        }];
                    });
                }];
            }
        });
    }];
    
    operation.descriptor = descriptor;
    operation.handler = handler;
    
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (VIMRequestOperation *)VIMRequestOperationWithRequest:(NSURLRequest *)request success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    VIMRequestOperation *operation = [[VIMRequestOperation alloc] initWithRequest:request];
    
    operation.responseSerializer = self.responseSerializer;
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.completionQueue = self.completionQueue;
    operation.completionGroup = self.completionGroup;
    
    return operation;
}

- (void)generateResponseFromJSON:(id)JSON operation:(VIMRequestOperation *)operation completionBlock:(VIMRequestCompletionBlock)completionBlock
{
    [VIMServerResponseMapper responseFromJSON:JSON operation:operation completionBlock:completionBlock];
}

- (NSError *)_parseServerError:(NSError *)error
{
    return [NSError errorFromServerError:error withNewDomain:kVimeoServerErrorDomain];
}

#pragma mark Utilities

- (id)cleanParameters:(id)parameters
{
    if (parameters == nil)
    {
        parameters = [NSMutableDictionary dictionary];
    }
    
    if ([parameters isKindOfClass:[NSDictionary class]])
    {
        if ([parameters isKindOfClass:[NSMutableDictionary class]] == NO)
        {
            parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        }
        
        if ([[parameters allKeys] count] == 0)
        {
            parameters = nil;
        }
    }
    
    return parameters;
}

NSDictionary *VIMParametersFromQueryString(NSString *queryString)
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (queryString)
    {
        NSScanner *parameterScanner = [[NSScanner alloc] initWithString:queryString];
        NSString *name = nil;
        NSString *value = nil;
        
        while (![parameterScanner isAtEnd])
        {
            name = nil;
            
            [parameterScanner scanUpToString:@"=" intoString:&name];
            [parameterScanner scanString:@"=" intoString:NULL];
            
            value = nil;
            
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:NULL];
            
            if (name && value)
            {
                [parameters setValue:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    
    return parameters;
}

@end
