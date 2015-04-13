//
//  VIMFeaturesConfiguration.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 11/13/14.
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
