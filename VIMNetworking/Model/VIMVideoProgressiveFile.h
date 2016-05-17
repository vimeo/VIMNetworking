//
//  VIMVideoProgressiveFile.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

@import Foundation;
#import "VIMVideoPlayFile.h"

@interface VIMVideoProgressiveFile : VIMVideoPlayFile

@property (nonatomic, assign) CGSize dimensions;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, copy, nullable) NSString *mimeType;
@property (nonatomic, strong, nullable) NSNumber *fps;
@property (nonatomic, copy, nullable) NSString *md5;
@property (nonatomic, strong, nullable) NSNumber *sizeInBytes;

- (BOOL)isSupportedMimeType;

@end
