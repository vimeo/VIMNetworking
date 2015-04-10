//
//  VIMFeaturesConfiguration.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/13/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMFeaturesConfiguration.h"

@interface VIMFeaturesConfiguration ()

@property (nonatomic, strong) NSMutableDictionary *ios;

@property (nonatomic, assign, readwrite) BOOL autouploadEnabled;
@property (nonatomic, assign, readwrite) BOOL iapEnabled;
@property (nonatomic, assign, readwrite) BOOL comScoreEnabled;
@property (nonatomic, assign, readwrite) BOOL playTrackingEnabled;
@property (nonatomic, strong, readwrite) NSString *chromecastReceiverAppID;

@end

@implementation VIMFeaturesConfiguration

#pragma mark - VIMMappable

- (Class)getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"ios"])
        return [NSMutableDictionary class];
    
    return nil;
}

- (void)didFinishMapping
{
    [self parseFeatures];
}

- (void)parseFeatures
{
    if (self.ios)
    {
        self.iapEnabled = [self.ios[@"iap"] boolValue];
        self.autouploadEnabled = [self.ios[@"autoupload"] boolValue];
        self.comScoreEnabled = [self.ios[@"comscore"] boolValue];
        self.playTrackingEnabled = [self.ios[@"play_tracking"] boolValue];
        
        NSString *appID = self.ios[@"chromecast_app_id"];
        if (appID == nil || appID == (NSString *)[NSNull null]) {
            appID = @"";
        }
        self.chromecastReceiverAppID = appID;
    }
}

@end
