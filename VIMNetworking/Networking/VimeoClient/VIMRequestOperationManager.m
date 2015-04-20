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
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "VIMMappable.h"
#import "VIMObjectMapper.h"
#import "VIMCache.h"
#import "VIMRequestDescriptor.h"
#import "VIMRequestToken.h"
#import "VIMRequestOperation.h"
#import "VIMUser.h"
#import "VIMConnection.h"
#import "VIMServerResponse.h"
#import "VIMNetworking.h"
#import "VIMAccount.h"
#import "VIMAccountStore.h"
#import "VIMAccountCredential.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"
#import "NSError+BaseError.h"
#import "VIMSession.h"
#import "VIMServerResponseMapper.h"

NSString * const kVimeoClientErrorDomain = @"VimeoClientErrorDomain";

@interface VIMRequestOperationManager ()
{
    dispatch_queue_t _responseQueue;
}

@end

@implementation VIMRequestOperationManager

+ (VIMRequestOperationManager *)sharedManager
{
    static VIMRequestOperationManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *URL = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
        _sharedClient = [[VIMRequestOperationManager alloc] initWithBaseURL:URL];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if(self)
    {
		_responseQueue = dispatch_queue_create("com.vimeo.VIMVimeoClient.responseQueue", DISPATCH_QUEUE_SERIAL);
        
        self.requestSerializer = [VIMRequestSerializer serializerWithSession:[VIMSession sharedSession]];
        self.responseSerializer = [VIMResponseSerializer serializer];        
    
#ifndef DEBUG
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        self.securityPolicy.allowInvalidCertificates = NO;
        self.securityPolicy.validatesCertificateChain = NO;
#endif
    }
    
    return self;
}

#pragma mark - Cancellation

- (void)cancelRequest:(id<VIMRequestToken>)request
{
    if ([request isKindOfClass:[VIMRequestOperation class]])
    {
        VIMRequestOperation *requestOperation = (VIMRequestOperation *)request;
        NSLog(@"cancelRequest: %@", requestOperation.request.URL.path);
        [requestOperation cancel];
    }
}

- (void)cancelAllRequestsForHandler:(id)handler
{
    if(handler == nil)
        return;
    
    for (NSOperation *operation in [self.operationQueue operations])
    {
        if ([operation isKindOfClass:[VIMRequestOperation class]])
        {
            if(((VIMRequestOperation *)operation).handler == handler)
            {
                NSLog(@"cancelAllRequestsForHandler: %@", NSStringFromClass([handler class]));
                [operation cancel];
            }
        }
    }
}

#pragma mark - Requests

- (id<VIMRequestToken>)fetchWithRequestDescriptor:(VIMRequestDescriptor *)descriptor handler:(id)handler completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    NSAssert([descriptor.parameters isKindOfClass:[NSArray class]] || [descriptor.parameters isKindOfClass:[NSDictionary class]] || descriptor.parameters == nil, @"Invalid parameters");
    
    if (descriptor.userConnectionKey.length > 0)
    {
        VIMConnection *connection = [[VIMSession sharedSession].authenticatedUser connectionWithName:descriptor.userConnectionKey];
        if(connection)
            descriptor.urlPath = connection.uri;
    }

    if (descriptor.parameters == nil)
    {
        descriptor.parameters = [NSMutableDictionary dictionary];
    }
    
    if ([descriptor.parameters isKindOfClass:[NSDictionary class]])
    {
        if ([descriptor.parameters isKindOfClass:[NSMutableDictionary class]] == NO)
        {
            descriptor.parameters = [NSMutableDictionary dictionaryWithDictionary:descriptor.parameters];
        }

        if ([[descriptor.parameters allKeys] count] == 0)
        {
            descriptor.parameters = nil;
        }
    }
    
    NSString *fullURLString = [[NSURL URLWithString:descriptor.urlPath relativeToURL:self.baseURL] absoluteString];
    
    NSError* __autoreleasing error = nil;
        
    NSURLRequest *urlRequest = [self.requestSerializer requestWithMethod:descriptor.HTTPMethod URLString:fullURLString parameters:descriptor.parameters error:&error];
    
    if(descriptor.cachePolicy == VIMCachePolicy_LocalOnly || descriptor.cachePolicy == VIMCachePolicy_LocalAndNetwork)
    {
        CFTimeInterval startTime = CACurrentMediaTime();
        NSLog(@"cache start (%@)", descriptor.urlPath);
        
        VIMRequestOperation *operation = [[VIMRequestOperation alloc] initWithRequest:urlRequest];
        operation.descriptor = descriptor;
        operation.handler = handler;
        
        // try to fetch from cache
        [[[VIMSession sharedSession] userCache] objectForKey:urlRequest.URL.absoluteString completionBlock:^(id JSON) {

            if(JSON == nil)
            {
                dispatch_async(_responseQueue, ^{
                    
                    CFTimeInterval endTime = CACurrentMediaTime();
                    NSLog(@"cache failure %g sec (%@)", endTime - startTime, descriptor.urlPath);

                    NSString *errorDescription = @"Could not fetch from cache";
                    NSError *error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
                    
                    VIMServerResponse *response = [[VIMServerResponse alloc] init];
                    response.request = operation;
                    response.isCachedResponse = YES;
                    
                    if(descriptor.cachePolicy == VIMCachePolicy_LocalOnly)
                        response.isFinalResponse = YES;
                    
                    if(completionBlock)
                        completionBlock(response, error);
                    
                });
            }
            else
            {
                dispatch_async(_responseQueue, ^{
                    
                    [self generateResponseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
                        
                        CFTimeInterval endTime = CACurrentMediaTime();
                        NSLog(@"cache success %g sec (%@)", endTime - startTime, descriptor.urlPath);

                        if(response)
                        {
                            response.isCachedResponse = YES;
                            
                            if(descriptor.cachePolicy == VIMCachePolicy_LocalOnly)
                                response.isFinalResponse = YES;
                        }
                        
                        if(completionBlock)
                            completionBlock(response, error);
                    }];
                });
            }

        }];
        
        if(descriptor.cachePolicy == VIMCachePolicy_LocalOnly)
            return operation;
    }
    
    CFTimeInterval startTime = CACurrentMediaTime();
    NSLog(@"server start (%@)", descriptor.urlPath);
    
    VIMRequestOperation *operation = [self VIMRequestOperationWithRequest:urlRequest success:^(AFHTTPRequestOperation *HTTPOperation, id JSON) {
        
        VIMRequestOperation *operation = (VIMRequestOperation *)HTTPOperation;
        
        if([operation isCancelled])
            return;
        
        // Save JSON to cache
        if (descriptor.shouldCacheResponse)
        {
            [[[VIMSession sharedSession] userCache] setObject:JSON forKey:urlRequest.URL.absoluteString];
        }
        
        dispatch_async(_responseQueue, ^{
            
            [self generateResponseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
                
                CFTimeInterval endTime = CACurrentMediaTime();
                NSLog(@"server success %g sec (%@)", endTime - startTime, descriptor.urlPath);

                if(response)
                    response.isFinalResponse = YES;
                
                if(completionBlock)
                    completionBlock(response, error);
            }];
        });
        
    } failure:^(AFHTTPRequestOperation *HTTPOperation, NSError *error) {
        
        CFTimeInterval endTime = CACurrentMediaTime();
        NSLog(@"server failure %g sec (%@)", endTime - startTime, descriptor.urlPath);

        VIMRequestOperation *operation = (VIMRequestOperation *)HTTPOperation;
        if([operation isCancelled])
            return;
        
        VIMServerResponse *response = [[VIMServerResponse alloc] init];
        response.request = operation;
        response.urlResponse = operation.response;
        response.isCachedResponse = NO;
        if(descriptor.cachePolicy != VIMCachePolicy_TryNetworkFirst)
            response.isFinalResponse = YES;
        
        NSError *parsedError = [self _parseServerError:error];
        if(parsedError)
            error = parsedError;
        
        if(completionBlock)
            completionBlock(response, error);
        
        if(descriptor.cachePolicy == VIMCachePolicy_TryNetworkFirst)
        {
            NSLog(@"fetchWithRequestDescriptor: Fetch from network failed. Trying to fetch from cache");
            
            // try to fetch from cache
            [[[VIMSession sharedSession] userCache] objectForKey:urlRequest.URL.absoluteString completionBlock:^(id JSON) {

                NSError *error = nil;

                if(JSON == nil)
                {
                    NSString *errorDescription = @"Could not fetch from cache";
                    error = [NSError errorWithDomain:kVimeoClientErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
                    
                    VIMServerResponse *response = [[VIMServerResponse alloc] init];
                    response.request = operation;
                    
                    response.isCachedResponse = YES;
                    response.isFinalResponse = YES;
                    
                    if(completionBlock)
                        completionBlock(response, error);
                }
                else
                {
                    dispatch_async(_responseQueue, ^{
                        
                        [self generateResponseFromJSON:JSON operation:operation completionBlock:^(VIMServerResponse *response, NSError *error) {
                            
                            if(response)
                            {
                                response.isCachedResponse = YES;
                                response.isFinalResponse = YES;
                            }
                            
                            if(completionBlock)
                                completionBlock(response, error);
                        }];
                    });
                }

            }];
        }
    }];
    
    operation.descriptor = descriptor;
    operation.handler = handler;
    
    // Call completion block on background thread
    operation.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [self.operationQueue addOperation:operation]; // This used to be added to the sharedManager's queue, why? [AH]
    
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

- (void)generateResponseFromJSON:(id)JSON operation:(VIMRequestOperation *)operation completionBlock:(VIMFetchCompletionBlock)completionBlock
{
    [VIMServerResponseMapper responseFromJSON:JSON operation:operation completionBlock:completionBlock];
}

- (NSError *)_parseServerError:(NSError *)error
{
    return [NSError errorFromServerError:error withNewDomain:kVimeoServerErrorDomain];
}

@end
