//
//  VIMFileManagerRemoveFileTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/18/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMRemoveFileTask.h"
#import "VIMTaskDebugger.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"

@implementation VIMRemoveFileTask

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];

    if (self.filePath == nil)
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: self.filePath is nil"];
        
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToRemoveFileErrorCode message:@"self.filePath is nil"];
        
        if (self.completionBlock)
        {
            self.completionBlock(self.error);
        }
        
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager new];
    
    if (![fileManager fileExistsAtPath:self.filePath isDirectory:nil])
    {
        // TODO: sfredieu end task with success;

        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Failed: Unable to remove file, file doesn't exist"];

        if (self.completionBlock)
        {
            self.completionBlock(nil);
        }

        return;
    }
    
    NSError *error = nil;
    if ([fileManager removeItemAtPath:self.filePath error:&error] == NO)
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:[NSString stringWithFormat:@"Unable to remove file %@", error]];
        
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToRemoveFileErrorCode baseError:error];
    }
    else
    {
        [VIMTaskDebugger debugLogWithClass:[self class] message:@"Success"];
    }
    
    if (self.completionBlock)
    {
        self.completionBlock(self.error);
    }
}

@end
