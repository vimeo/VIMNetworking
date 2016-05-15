//
//  VIMVideoPlayFile.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoPlayFile.h"
#import "VIMVideoLog.h"

@interface VIMVideoPlayFile()

@property (nonatomic, copy) NSString *expires;

@end

@implementation VIMVideoPlayFile

#pragma mark - NSCoding

+ (void)load
{
    // This appeared to only be necessary for downloaded videos with archived VIMVideoFile's that persisted in a failed state. [NL] 05/15/16
    // E.g. a user has at least one failed download with our legacy VIMVideoFile model, then upgrades to this version.
    // When the user launches the app, we must force unwrap the video file in NewDownloadDescriptor as a VIMVideoPlayFile to be in sync with our current model. The following allows us to do so by unarchiving VIMVideoFile as VIMVideoPlayFile.
    [NSKeyedUnarchiver setClass:self forClassName:@"VIMVideoFile"];
}

#pragma mark - VIMMappable

- (void)didFinishMapping
{
    if ([self.expires isKindOfClass:[NSString class]])
    {
        self.expirationDate = [[VIMModelObject dateFormatter] dateFromString:self.expires];
    }
    else
    {
        self.expirationDate = nil;
    }
}

- (NSDictionary *)getObjectMapping
{
    return @{@"link_expiration_time": @"expires"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"log"])
    {
        return [VIMVideoLog class];
    }
    return nil;
}

#pragma mark - Instance methods

- (BOOL)isExpired
{
    if (!self.expirationDate) // This will yield NSOrderedSame (weird), so adding an explicit check here [AH] 9/14/2015
    {
        return NO;
    }
    
    NSComparisonResult result = [[NSDate date] compare:self.expirationDate];
    
    return (result == NSOrderedDescending);
}

@end
