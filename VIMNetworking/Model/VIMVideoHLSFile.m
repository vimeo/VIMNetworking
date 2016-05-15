//
//  VIMVideoHLSFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoHLSFile.h"

@implementation VIMVideoHLSFile

#pragma mark - VIMVideoPlayFile override

- (NSString *)qualityString
{
    return @"hls";
}

@end
