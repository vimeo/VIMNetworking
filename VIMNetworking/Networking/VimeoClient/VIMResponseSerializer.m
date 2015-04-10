//
//  VIMVimeoResponseSerializer.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMResponseSerializer.h"

@implementation VIMResponseSerializer

+ (instancetype)serializer
{
    VIMResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = 0;
    [serializer setAcceptableContentTypes:[VIMResponseSerializer acceptableContentTypes]];
    
    return serializer;
}

+ (NSSet *)acceptableContentTypes
{
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/html", @"text/javascript", @"application/vnd.vimeo.video+json", @"application/vnd.vimeo.cover+json", @"application/vnd.vimeo.service+json", @"application/vnd.vimeo.comment+json", @"application/vnd.vimeo.user+json", @"application/vnd.vimeo.activity+json", @"application/vnd.vimeo.uploadticket+json", @"application/vnd.vimeo.error+json", @"application/vnd.vimeo.trigger+json", nil];
}

@end
