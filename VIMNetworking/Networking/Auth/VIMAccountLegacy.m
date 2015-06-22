//
//  VIMAccount.m
//  VIMNetworking
//
//  Created by Kashif Muhammad on 10/28/13.
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

#import "VIMAccountLegacy.h"
#import "VIMCredentialLegacy.h"

@interface VIMAccountLegacy () <NSCoding, NSSecureCoding>

@end

@implementation VIMAccountLegacy

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        // TODO: need to use decodeObjectOfClass but this is type id, what to do? [AH]
        
        id response = nil;
        @try
        {
            response = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"serverResponse"];
        }
        @catch (NSException *exception)
        {
            @try
            {
                response = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"serverResponse"];
            }
            @catch (NSException *exception)
            {
                NSLog(@"Unable to unarchive server response");
            }
        }

        self.username = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"username"];
        self.serverResponse = response;
        self.userData = [aDecoder decodeObjectOfClass:[NSMutableDictionary class] forKey:@"userData"];
        self.credential = [aDecoder decodeObjectOfClass:[VIMCredentialLegacy class] forKey:@"credential"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.serverResponse forKey:@"serverResponse"];
    [aCoder encodeObject:self.userData forKey:@"userData"];
    [aCoder encodeObject:self.credential forKey:@"credential"];
}

@end
