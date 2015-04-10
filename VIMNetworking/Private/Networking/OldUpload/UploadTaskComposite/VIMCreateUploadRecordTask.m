//
//  AFNetCreateUploadRecordTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/17/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//


#import "VIMCreateUploadRecordTask.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"
#import "VIMSession.h"
#import "VIMUploadRecord.h"
#import "VIMTaskDebugger.h"
#import "VIMRequestOperationManager.h"

NSString *const VIMRecordCreationURLStringVideos = @"/me/videos";

@interface VIMCreateUploadRecordTask ()

@property (nonatomic, strong, readwrite) VIMUploadRecord *uploadRecord;

@end

@implementation VIMCreateUploadRecordTask

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];
    
    NSString *URL = [NSString stringWithFormat:@"%@%@", [[VIMSession sharedSession] baseURLString], VIMRecordCreationURLStringVideos];
    
    NSDictionary *parameters = @{@"type" : @"streaming"};
    
    __weak typeof(self) weakSelf = self;
    self.operation = [[VIMRequestOperationManager sharedManager] POST:URL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        VIMUploadRecord *uploadRecord = [[VIMUploadRecord alloc] init];
        NSError *error = nil;
        
        if (operation.response.statusCode >= 200 && operation.response.statusCode <= 299)
        {
            uploadRecord.completeURI = [responseObject objectForKey:@"complete_uri"];
            uploadRecord.uploadURISecure = [responseObject objectForKey:@"upload_uri_secure"];
        
            if (uploadRecord.completeURI == nil || uploadRecord.uploadURISecure == nil)
            {
                weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCreateRecordErrorCode baseError:error];
                
                [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failure: %@", error]];
            }
            else
            {
                weakSelf.uploadRecord = uploadRecord;
            
                [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"Success"];
            }
        }
        
        if (weakSelf.completionBlock)
        {
            weakSelf.completionBlock(weakSelf.error);
        }
        
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failure: %@", error]];

        weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCreateRecordErrorCode baseError:error];
        
        if (weakSelf.completionBlock)
        {
            weakSelf.completionBlock(weakSelf.error);
        }
        
    }];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.uploadRecord = [aDecoder decodeObjectForKey:@"uploadRecord"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.uploadRecord forKey:@"uploadRecord"];
}

@end
