//
//  VIMVideo.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/23/13.
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

#import "VIMModelObject.h"

@class VIMUser;
@class VIMVideoFile;
@class VIMConnection;
@class VIMPictureCollection;
@class VIMInteraction;
@class VIMPrivacy;
@class VIMAppeal;
@class VIMVideoLog;

@interface VIMVideo : VIMModelObject

@property (nonatomic, copy) NSArray *contentRating;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, copy) NSString *videoDescription;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, copy) NSString *license;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;
@property (nonatomic, strong) NSDictionary *stats;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) VIMUser *user;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) VIMAppeal *appeal;
@property (nonatomic, strong) VIMPrivacy *privacy;
@property (nonatomic, strong) VIMVideoLog *log;
@property (nonatomic, strong) NSNumber *numPlays;
@property (nonatomic, strong) NSArray *categories;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

// Helpers

- (BOOL)canViewInfo;
- (BOOL)canComment;
- (BOOL)canViewComments;
- (BOOL)isVOD;
- (BOOL)isPrivate;
- (BOOL)isAvailable;

@end
