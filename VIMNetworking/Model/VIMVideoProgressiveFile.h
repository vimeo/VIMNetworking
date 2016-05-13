//
//  VIMVideoProgressiveFile.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

@import Foundation;
#import "VIMVideoFileProtocol.h"

@interface VIMVideoProgressiveFile : VIMModelObject <VIMVideoFileProtocol>

@property (nonatomic, copy, nullable) NSString *link;
@property (nonatomic, strong, nullable) VIMVideoLog *log;
@property (nonatomic, strong, nullable) NSDate *expirationDate;

@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, strong, nullable) NSNumber *size;
@property (nonatomic, strong, nullable) NSNumber *width;
@property (nonatomic, strong, nullable) NSNumber *height;

- (BOOL)isSupportedMimeType;
- (BOOL)isExpired;

@end
