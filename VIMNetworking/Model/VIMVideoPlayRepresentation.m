//
//  VIMVideoPlayRepresentation.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//


#import "VIMVideoPlayRepresentation.h"
#import "VIMVideoHLSFile.h"
#import "VIMVideoDASHFile.h"
#import "VIMVideoProgressiveFile.h"
#import "VIMVideoLog.h"

@interface VIMVideoPlayRepresentation()

@property (nonatomic, copy, nullable) NSString *status;

@end

@implementation VIMVideoPlayRepresentation

#pragma mark - VIMMappable

- (void)didFinishMapping
{
    [self setPlayabilityStatus];
}

- (NSDictionary *)getObjectMapping
{
    return @{@"progressive": @"progressiveFiles",
             @"hls": @"hlsFile",
             @"dash": @"dashFile"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if( [key isEqualToString:@"hls"] )
    {
        return [VIMVideoHLSFile class];
    }
    
    if( [key isEqualToString:@"dash"] )
    {
        return [VIMVideoDASHFile class];
    }
    
    return nil;
}

- (Class)getClassForCollectionKey:(NSString *)key
{
    if([key isEqualToString:@"progressive"])
    {
        return [VIMVideoProgressiveFile class];
    }
    
    return nil;
}

- (void)setPlayabilityStatus
{
    NSDictionary *statusDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:VIMVideoPlayabilityStatusUnavailable], @"unavailable",
                                      [NSNumber numberWithInt:VIMVideoPlayabilityStatusPlayable], @"playable",
                                      [NSNumber numberWithInt:VIMVideoPlayabilityPurchaseRequired], @"purchase_required",
                                      [NSNumber numberWithInt:VIMVideoPlayabilityRestricted], @"restricted",
                                      nil];
    
    NSNumber *number = [statusDictionary objectForKey:self.status];
    
    NSAssert(number != nil, @"Playability status not handled, unknown playability status");
    
    self.playabilityStatus = [number intValue];
}

@end