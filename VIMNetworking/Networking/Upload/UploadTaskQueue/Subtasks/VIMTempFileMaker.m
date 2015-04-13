//
//  VIMTempFileTask.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/8/15.
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

#import "VIMTempFileMaker.h"
#import "VIMSession.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

static const NSString *VIMTempFileMakerErrorDomain = @"VIMTempFileMakerErrorDomain";

@implementation VIMTempFileMaker

#pragma mark - Public API

+ (void)tempFileFromURLAsset:(AVURLAsset *)URLAsset completionBlock:(TempFileCompletionBlock)completionBlock
{
    if ([[URLAsset.URL scheme] isEqualToString:@"assets-library"])
    {
        [self exportAsset:URLAsset completionBlock:completionBlock];
    }
    else
    {
        [self copyURLAsset:URLAsset withCompletionBlock:completionBlock];
    }
}

+ (void)tempFileFromPHAsset:(PHAsset *)phAsset completionBlock:(TempFileCompletionBlock)completionBlock
{
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    
    __weak typeof(self) welf = self;
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        NSError *error = info[PHImageErrorKey];
        if (error)
        {
            if (completionBlock)
            {
                completionBlock(nil, error);
            }
            
            return;
        }
        
        if ([asset isKindOfClass:[AVURLAsset class]]) // ALAsset videos, et al
        {
            AVURLAsset *URLAsset = (AVURLAsset *)asset;
            [self copyURLAsset:URLAsset withCompletionBlock:completionBlock];
            
            return;
        }
        
        if ([asset isKindOfClass:[AVComposition class]]) // Slomo videos
        {
            [self exportAsset:asset completionBlock:completionBlock];
            
            return;
        }

        error = [NSError errorWithDomain:(NSString *)VIMTempFileMakerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot upload unknown AVAsset type."}];
            
        if (completionBlock)
        {
            completionBlock(nil, error);
        }
        
    }];
}

#pragma mark - Private API

+ (void)exportAsset:(AVAsset *)asset completionBlock:(TempFileCompletionBlock)completionBlock
{
    // Per the docs AVAssetExportPresetPassthrough will never appear in the list returned from exportPresetsCompatibleWithAsset: [AH]
    //    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.URLAsset];
    //    if (![compatiblePresets containsObject:AVAssetExportPresetPassthrough])
    //    {
    //        if (completionBlock)
    //        {
    //            NSError *error = [NSError errorWithDomain:(NSString *)VIMCreateRecordTaskErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Incompatible export preset."}];
    //            completionBlock(nil, error);
    //        }
    //
    //        return;
    //    }
    
    if (![asset isExportable])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:(NSString *)VIMTempFileMakerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Asset is not exportable."}];
            completionBlock(nil, error);
        }
        
        return;
    }
    
    if ([asset hasProtectedContent])
    {
        if (completionBlock)
        {
            NSError *error = [NSError errorWithDomain:(NSString *)VIMTempFileMakerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Asset is not exportable (has protected content)."}];
            completionBlock(nil, error);
        }
        
        return;
    }
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    NSString *extension = (__bridge  NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)exportSession.outputFileType, kUTTagClassFilenameExtension);
    
    NSString *path = [self uniqueAppGroupPathWithExtension:extension];
    exportSession.outputURL = [NSURL fileURLWithPath:path];
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    __weak typeof(self) welf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (exportSession.error)
        {
            if (completionBlock)
            {
                completionBlock(nil, exportSession.error);
            }
            
            return;
        }
        
        if (exportSession.status != AVAssetExportSessionStatusCompleted)
        {
            if (completionBlock)
            {
                NSError *error = [NSError errorWithDomain:(NSString *)VIMTempFileMakerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Export did not succeed."}];
                completionBlock(nil, error);
            }
            
            return;
        }
        
        if (completionBlock)
        {
            completionBlock(path, nil);
        }
        
    }];
}

+ (void)copyURLAsset:(AVURLAsset *)URLAsset withCompletionBlock:(TempFileCompletionBlock)completionBlock
{
    NSString *extension = [URLAsset.URL pathExtension];
    NSURL *destinationURL = [NSURL fileURLWithPath:[self uniqueAppGroupPathWithExtension:extension]];
    
    NSError *copyError = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:URLAsset.URL toURL:destinationURL error:&copyError];
    
    if (success)
    {
        if (completionBlock)
        {
            NSString *path = [destinationURL path];
            completionBlock(path, nil);
        }
    }
    else
    {
        if (completionBlock)
        {
            completionBlock(nil, copyError);
        }
    }
}

#pragma mark - Utilities

+ (NSString *)uniqueAppGroupPathWithExtension:(NSString *)extension
{
    NSString *basePath = [self appGroupExportsDirectory];
    
    NSString *filename = [[NSProcessInfo processInfo] globallyUniqueString];
    
    filename = [filename stringByAppendingPathExtension:extension];
    
    NSString *path = [basePath stringByAppendingPathComponent:filename];
    
    return path;
}

+ (NSString *)appGroupExportsDirectory
{
    NSURL *groupURL = nil;
    
    NSString *sharedContainerID = [[VIMSession sharedSession] sharedContainerID]; // TODO: eliminate VIMSession dependency [AH]
    if (sharedContainerID)
    {
        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:sharedContainerID];
    }
    
    //#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    //    if ([self.sessionManager.session.configuration respondsToSelector:@selector(sharedContainerIdentifier)])
    //    {
    //        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.sessionManager.session.configuration.sharedContainerIdentifier];
    //    }
    //#endif
    
    if (groupURL == nil)
    {
        groupURL = [NSURL URLWithString:NSTemporaryDirectory()];
    }
    
    NSString *uploadsDirectoryName = @"uploads";
    NSString *groupPath = [[groupURL path] stringByAppendingPathComponent:uploadsDirectoryName];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:groupPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Unable to create export directory: %@", error);
        
        return [NSTemporaryDirectory() stringByAppendingPathComponent:uploadsDirectoryName];
    }
    
    return groupPath;
}

@end
