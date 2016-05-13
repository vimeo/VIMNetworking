//
//  VIMVideoPlayRepresentation.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoPlayRepresentation.h"
#import "VIMVideoHLSFile.h"
#import "VIMVideoProgressiveFile.h"
#import "VIMVideoLog.h"

@implementation VIMVideoPlayRepresentation

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"progressive": @"progressiveFiles"};
}

- (Class) getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"hls"])
    {
        return [VIMVideoHLSFile class];
    }
    
    return nil;
}

- (Class) getClassForCollectionKey:(NSString *)key
{
    if([key isEqualToString:@"progressive"])
    {
        return [VIMVideoProgressiveFile class];
    }
    
    return nil;
}

@end