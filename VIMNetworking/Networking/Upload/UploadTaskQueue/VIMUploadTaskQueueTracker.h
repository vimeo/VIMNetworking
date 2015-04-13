//
//  UploadQueueTracker.h
//  Smokescreen
//
//  Created by Hanssen, Alfie on 4/3/15.
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

#import <Foundation/Foundation.h>

@class VIMVideoAsset;

extern NSString *const VIMUploadTaskQueueTracker_CurrentVideoAssetDidChangeNotification;
extern NSString *const VIMUploadTaskQueueTracker_DidRefreshQueuedAssetsNotification;
extern NSString *const VIMUploadTaskQueueTracker_DidAddQueuedAssetsNotification;
extern NSString *const VIMUploadTaskQueueTracker_DidRemoveQueuedAssetsNotification;
extern NSString *const VIMUploadTaskQueueTracker_DidRemoveFailedAssetsNotification;
extern NSString *const VIMUploadTaskQueueTracker_QueuedAssetDidFailNotification;
extern NSString *const VIMUploadTaskQueueTracker_FailedAssetDidRetryNotification;

extern NSString *const VIMUploadTaskQueueTracker_AssetIndicesKey;
extern NSString *const VIMUploadTaskQueueTracker_OriginalIndexKey;
extern NSString *const VIMUploadTaskQueueTracker_NewIndexKey;
extern NSString *const VIMUploadTaskQueueTracker_QueuedAssetsKey;
extern NSString *const VIMUploadTaskQueueTracker_FailedAssetsKey;

@interface VIMUploadTaskQueueTracker : NSObject

@property (nonatomic, strong, readonly) VIMVideoAsset *currentVideoAsset;
@property (nonatomic, strong, readonly) NSMutableArray *videoAssets;
@property (nonatomic, strong, readonly) NSMutableArray *failedAssets;

- (instancetype)initWithName:(NSString *)name;

// This method must be called when a user "ignores" a failed asset [AH]
- (void)ignoreFailedAsset:(VIMVideoAsset *)videoAsset;

@end
