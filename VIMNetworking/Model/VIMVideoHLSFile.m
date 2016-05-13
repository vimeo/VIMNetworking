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

- (BOOL)isSupportedMimeType
{
    //no mimetype provided, what should be default for hls
    //return [AVURLAsset isPlayableExtendedMIMEType:self.type];
    return YES;
}

@end
