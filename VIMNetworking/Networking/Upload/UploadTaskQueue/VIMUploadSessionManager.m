//
//  UploadSessionManager.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/29/15.
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

#import "VIMUploadSessionManager.h"
#import "NSURLSessionConfiguration+Extensions.h"
#import "VIMSession.h"
#import "VIMRequestSerializer.h"
#import "VIMResponseSerializer.h"

@implementation VIMUploadSessionManager

+ (instancetype)sharedAppInstance
{
    static VIMUploadSessionManager *sharedAppInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[[VIMSession sharedSession] backgroundSessionIdentifierApp] sharedContainerID:[[VIMSession sharedSession] sharedContainerID]];
        
        sharedAppInstance = [[self alloc] initWithSessionConfiguration:configuration];

    });
    
    return sharedAppInstance;
}

+ (instancetype)sharedExtensionInstance
{
    static VIMUploadSessionManager *sharedExtensionInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithID:[[VIMSession sharedSession] backgroundSessionIdentifierExtension] sharedContainerID:[[VIMSession sharedSession] sharedContainerID]];
        
        sharedExtensionInstance = [[self alloc] initWithSessionConfiguration:configuration];
        
    });
    
    return sharedExtensionInstance;
}

#pragma mark - Private API

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSURL *url = [NSURL URLWithString:[[VIMSession sharedSession] baseURLString]];
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)

    {
        self.requestSerializer = [VIMRequestSerializer serializerWithSession:[VIMSession sharedSession]];
        self.responseSerializer = [VIMResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        self.securityPolicy.allowInvalidCertificates = NO;
        self.securityPolicy.validatesCertificateChain = NO;
        self.securityPolicy.validatesDomainName = YES;
    }

    return self;
}

@end
