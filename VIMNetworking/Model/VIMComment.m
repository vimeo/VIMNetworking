//
//  VIMComment.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/25/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMComment.h"
#import "VIMUser.h"
#import "NSString+MD5.h"

@interface VIMComment ()

@property (nonatomic, strong) NSMutableDictionary *metadata;

@end

@implementation VIMComment

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"total" : @"totalReplies",
             @"replies" : @"repliesURI"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if([key isEqualToString:@"user"])
        return [VIMUser class];
    
    return nil;
}

- (void)didFinishMapping
{
    self.objectID = [self.uri MD5];

    if([self.dateCreated isKindOfClass:[NSString class]])
        self.dateCreated = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.dateCreated];
    
    [self parseReplies];
}

- (void)parseReplies
{
    if (self.metadata)
    {
        NSDictionary *connections = self.metadata[@"connections"];
        if (connections && [connections isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *replies = connections[@"replies"];
            if (replies && [replies isKindOfClass:[NSDictionary class]])
            {
                self.totalReplies = replies[@"total"];
                if (![self.totalReplies isKindOfClass:[NSNumber class]])
                {
                    self.totalReplies = @(0);
                }
                
                self.repliesURI = replies[@"uri"];
                if (![self.repliesURI isKindOfClass:[NSString class]])
                {
                    self.repliesURI = nil;
                }
            }
        }
    }
}

@end
