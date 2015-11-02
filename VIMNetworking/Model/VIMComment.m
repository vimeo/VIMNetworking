//
//  VIMComment.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 9/25/14.
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

#import "VIMComment.h"
#import "VIMUser.h"
#import "NSString+MD5.h"

@interface VIMComment ()

@property (nonatomic, strong) NSMutableDictionary *metadata;

@end

@implementation VIMComment

- (NSString *)objectID
{
    NSAssert([self.uri length] > 0, @"Object does not have a uri, cannot generate objectID");
    
    return [self.uri MD5];
}

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"total" : @"totalReplies",
             @"replies" : @"repliesURI"};
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"user"])
    {
        return [VIMUser class];
    }
    
    return nil;
}

- (void)didFinishMapping
{
    if ([self.createdOn isKindOfClass:[NSString class]])
    {
        self.createdOn = [[VIMModelObject dateFormatter] dateFromString:(NSString *)self.createdOn];
    }
    
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
