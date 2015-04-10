//
//  VIMPictureCollection.h
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 9/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

#import <CoreGraphics/CoreGraphics.h>

@class VIMPicture;

@interface VIMPictureCollection : VIMModelObject

@property (strong, nonatomic) NSString *uri;
@property (strong, nonatomic) NSArray *pictures;

- (VIMPicture *)pictureForHeight:(CGFloat)height;
- (VIMPicture *)pictureForWidth:(CGFloat)width;

@end
