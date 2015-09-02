//
//  VIMVimeoSessionManager.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 6/4/14.
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

#import "VIMSessionManager.h"
#import "NSURLSessionConfiguration+Extensions.h"
#import "VIMJSONResponseSerializer.h"
#import "VIMJSONRequestSerializer.h"
#import "VIMSession.h"
#import "VIMSessionConfiguration.h"
#import "VIMJSONResponseSerializer.h"

@interface VIMSessionManager () <VIMRequestSerializerDelegate>

@end

@implementation VIMSessionManager

- (instancetype)initWithDefaultSession
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [self initWithBaseURL:baseURL sessionConfiguration:nil];
}

- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID
{
    return [self initWithBackgroundSessionID:sessionID sharedContainerID:nil];
}

- (instancetype)initWithBackgroundSessionID:(NSString *)sessionID sharedContainerID:(NSString *)sharedContainerID
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:sessionID sharedContainerID:sharedContainerID];
    
    return [self initWithSessionConfiguration:configuration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSURL *baseURL = [NSURL URLWithString:[VIMSession sharedSession].configuration.baseURLString];
    
    return [self initWithBaseURL:baseURL sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)
    {
        [self initialSetup];
    }
    
    return self;
}

- (void)initialSetup
{
    self.requestSerializer = [[VIMJSONRequestSerializer alloc] initWithAPIVersionString:[VIMSession sharedSession].configuration.APIVersionString];
    self.responseSerializer = [VIMJSONResponseSerializer serializer];
}

#pragma mark - VIMRequestSerializerDelegate

- (NSString *)authorizationHeaderValue:(VIMJSONRequestSerializer *)serializer
{
    return nil;
}

@end
