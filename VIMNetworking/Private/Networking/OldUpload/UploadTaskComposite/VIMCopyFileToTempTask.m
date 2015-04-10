//
//  VIMCopyALAssetToTempTask.m
//  VIMNetworking
//
//  Created by Fredieu, Stephen on 6/18/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMCopyFileToTempTask.h"
#import "VIMUploadErrorDomain.h"
#import "NSError+BaseError.h"
#import <AVFoundation/AVFoundation.h>
#import "VIMNetworking.h"
#import "VIMLocalAsset.h"

#import "VIMTaskDebugger.h"

@implementation VIMCopyFileToTempTask

- (void)start
{
    [VIMTaskDebugger debugLogWithClass:[self class] message:@"Start"];

    if (self.localAsset == nil)
    {
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCopyFileErrorCode message:@"Invalid self.localAsset"];

        if (self.completionBlock)
        {
            self.completionBlock(nil, self.error);
        }
        
        return;
    }
    
    BOOL isAssetURL = self.localAsset.url && [[self.localAsset.url scheme] isEqualToString:@"assets-library"];
    if(self.localAsset.url && !isAssetURL)
    {
        // This is a file url, just copy to temp path (extension from photos app uses this) [AH]
        
        NSString *tempPath = [self tempVideoFilepath];
        
        NSError *error = nil;
        [[NSFileManager new] copyItemAtURL:self.localAsset.url toURL:[NSURL fileURLWithPath:tempPath] error:&error];
        
        if (self.completionBlock)
        {
            if(error)
            {
                self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCopyFileErrorCode baseError:error];

                [VIMTaskDebugger debugLogWithClass:[self class] message:[NSString stringWithFormat:@"Failure: %@", error]];
                
                self.completionBlock(nil, self.error);
            }
            else
            {
                [VIMTaskDebugger debugLogWithClass:[self class] message:@"Success"];
                
                self.tmpPath = tempPath;
                
                self.completionBlock(self.tmpPath, nil);
            }
        }
        
        return;
    }
    
    if ([self.exportPreset length] == 0)
    {
        self.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCopyFileErrorCode message:@"Invalid self.exportSession"];

        if (self.completionBlock)
        {
            self.completionBlock(nil, self.error);
        }
        
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.localAsset requestExportSessionWithPreset:self.exportPreset completionBlock:^(AVAssetExportSession *exportSession, NSError *error) {
        
        if (error || exportSession == nil)
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"requestExportSessionWithPreset failure: %@", error]];
            
            weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCopyFileErrorCode baseError:error];

            if (weakSelf.completionBlock)
            {
                weakSelf.completionBlock(nil, weakSelf.error);
            }
        }
        else
        {
            [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"requestExportSessionWithPreset success"];

            NSString *tempPath = [weakSelf tempVideoFilepath];
            
            NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempPath.lastPathComponent];
            
            exportSession.outputFileType = AVFileTypeQuickTimeMovie;
            exportSession.outputURL = [NSURL fileURLWithPath:exportPath];
            
            [weakSelf exportWithSession:exportSession completionBlock:^(NSURL *url, NSError *error) {
                
                if(error == nil)
                {
                    if([exportPath isEqualToString:tempPath] == NO)
                    {
                        NSError *copyError = nil;
                        [[NSFileManager new] copyItemAtPath:exportPath toPath:tempPath error:&copyError];
                        error = copyError;
                    }
                }
                
                if(error)
                {
                    [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:[NSString stringWithFormat:@"exportWithSession failure: %@", error]];
                    
                    weakSelf.error = [NSError errorWithDomain:VIMNetworkingUploadErrorDomain code:UnableToCopyFileErrorCode baseError:error];
                    
                    if (weakSelf.completionBlock)
                    {
                        weakSelf.completionBlock(nil, weakSelf.error);
                    }
                }
                else
                {
                    [VIMTaskDebugger debugLogWithClass:[weakSelf class] message:@"exportWithSession success"];

                    weakSelf.tmpPath = tempPath;
                    
                    if (weakSelf.completionBlock)
                    {
                        weakSelf.completionBlock(weakSelf.tmpPath, nil);
                    }
                }
                
            }];
        }
    }];
}

- (void)exportWithSession:(AVAssetExportSession *)exportSession completionBlock:(void (^)(NSURL *url, NSError *error))completionBlock
{
    [exportSession exportAsynchronouslyWithCompletionHandler:^
     {
         if (exportSession.status != AVAssetExportSessionStatusCompleted)
         {
             if(completionBlock)
                 completionBlock(nil, exportSession.error);
         }
         else
         {
             if(completionBlock)
                 completionBlock(exportSession.outputURL, nil);
         }
     }];
}

- (NSString *)tempVideoFilepath
{
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *filename = [NSString stringWithFormat:@"tmp_video_%@.mp4", uniqueString];
    NSString *tmpDir = [[VIMSession sharedSession] appGroupTmpPath];
    
    return [tmpDir stringByAppendingPathComponent:filename];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.localAsset = [aDecoder decodeObjectForKey:@"localAsset"];
        self.exportPreset = [aDecoder decodeObjectForKey:@"exportPreset"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.localAsset forKey:@"localAsset"];
    [aCoder encodeObject:self.exportPreset forKey:@"exportPreset"];
}

@end
