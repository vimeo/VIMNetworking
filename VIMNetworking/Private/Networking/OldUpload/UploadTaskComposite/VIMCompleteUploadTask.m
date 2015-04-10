//
//  VIMCompleteUploadTask+Private.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMCompleteUploadTask.h"
#import "VIMSession.h"
#import "VIMTaskDebugger.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"
#import "AFNetworking.h"
#import "VIMRequestOperationManager.h"

@interface VIMCompleteUploadTask ()

@property (nonatomic, copy, readwrite) NSString *videoURI;

@end

@implementation VIMCompleteUploadTask

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];

    AFHTTPRequestOperationManager *manager = [VIMRequestOperationManager sharedManager];
    
    if (self.completeURI == nil)
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: Upload Complete URI is nil"];

        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCompleteUploadErrorCode message:@"self.completeURI is nil"];

        if (self.completionBlock)
        {
            self.completionBlock(nil, self.error);
        }
        
        return;
    }
    
    NSString *URL = [NSString stringWithFormat:@"%@%@", [[VIMSession sharedSession] baseURLString], self.completeURI];
    NSDictionary *parameters = @{@"file_name" : [[NSProcessInfo processInfo] globallyUniqueString]};
    
    __weak typeof(self) weakSelf = self;
    self.operation = [manager DELETE:URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *location = [[operation.response allHeaderFields] objectForKey:@"Location"];
        if (operation.response.statusCode >= 200 && operation.response.statusCode <= 299 && location)
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"Success"];

            weakSelf.videoURI = location;
            
            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(weakSelf.videoURI, nil);
            }
        }
        else
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failed: invalid status code %@", operation.responseObject]];
            
            weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCompleteUploadErrorCode message:@"Invalid status code or no location provided"];

            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(nil, weakSelf.error);
            }
        }
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failed: %@ %@", error, operation.responseObject]];
        
        weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCompleteUploadErrorCode baseError:error];

        if (weakSelf.completionBlock)
        {
            weakSelf.completionBlock(nil, weakSelf.error);
        }
    }];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.completeURI = [aDecoder decodeObjectForKey:@"completeURI"];
        self.videoURI = [aDecoder decodeObjectForKey:@"videoURI"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.completeURI forKey:@"completeURI"];
    [aCoder encodeObject:self.videoURI forKey:@"videoURI"];
}

@end
