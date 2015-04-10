//
//  VIMVideoPrivacyTask+Privacy.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMVideoMetadataTask.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"
#import "VIMAPIClient.h"

#import "VIMTaskDebugger.h"

@implementation VIMVideoMetadataTask

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];

    if (self.videoURI == nil)
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: self.videoURI cannot be nil"];
        
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToSetMetadataErrorCode message:@"self.videoURI cannot be nil"];
        
        if (self.completionBlock)
        {
            self.completionBlock(self.error);
        }
        
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [[VIMAPIClient sharedClient] updateVideoWithURI:self.videoURI title:self.videoName description:self.videoDescription privacy:self.videoPrivacy completionHandler:^(VIMServerResponse *response, NSError *error) {
        
        if(error)
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"Failed: error setting privacy %@", error]];

            weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToSetMetadataErrorCode baseError:error];

            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(weakSelf.error);
            }
        }
        else
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"Success"];

            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(nil);
            }
        }
    }];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.videoPrivacy = [aDecoder decodeObjectForKey:@"videoPrivacy"];
        self.videoName = [aDecoder decodeObjectForKey:@"videoName"];
        self.videoDescription = [aDecoder decodeObjectForKey:@"videoDescription"];
        self.videoURI = [aDecoder decodeObjectForKey:@"videoURI"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.videoPrivacy forKey:@"videoPrivacy"];
    [aCoder encodeObject:self.videoName forKey:@"videoName"];
    [aCoder encodeObject:self.videoDescription forKey:@"videoDescription"];
    [aCoder encodeObject:self.videoURI forKey:@"videoURI"];
}

@end
