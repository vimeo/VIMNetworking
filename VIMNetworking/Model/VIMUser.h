//
//  VIMUser.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 4/4/13.
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

#import <Foundation/Foundation.h>

#import "VIMModelObject.h"

@class VIMConnection;
@class VIMInteraction;
@class VIMPictureCollection;

typedef NS_ENUM(NSInteger, VIMUserAccountType)
{
    VIMUserAccountTypeBasic = 0,
    VIMUserAccountTypePro,
    VIMUserAccountTypePlus,
    VIMUserAccountTypeStaff
};

@interface VIMUser : VIMModelObject

@property (nonatomic, assign, readonly) VIMUserAccountType accountType;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *contentFilter;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;
@property (nonatomic, strong) id stats;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSArray *websites;
@property (nonatomic, strong) NSDictionary *uploadQuota;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

- (BOOL)hasCopyrightMatch;
- (BOOL)isFollowing;

- (NSString *)accountTypeAnalyticsIdentifier;

@end
