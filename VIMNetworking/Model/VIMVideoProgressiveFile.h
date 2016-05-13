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

@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, strong, nullable) NSNumber *size;
@property (nonatomic, strong, nullable) NSNumber *width;
@property (nonatomic, strong, nullable) NSNumber *height;

@end
