//
//  VIMPictureCollection.m
//  VIMNetworking
//
//  Created by Whitcomb, Andrew on 9/4/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "VIMPictureCollection.h"
#import "VIMPicture.h"

@implementation VIMPictureCollection

- (VIMPicture *)pictureForWidth:(CGFloat)width
{
    if (self.pictures.count == 0)
        return nil;
    
    if (width < 1)
    {
        width = 1;
    }
    
    VIMPicture *selectedPicture = [self.pictures lastObject];
    
    for (VIMPicture *picture in self.pictures)
    {
        if (picture.width.floatValue >= width && abs(picture.width.floatValue - width) < abs(selectedPicture.width.floatValue - width))
        {
            selectedPicture = picture;
        }
    }
    
    return selectedPicture;
}

- (VIMPicture *)pictureForHeight:(CGFloat)height
{
    if (self.pictures.count == 0)
        return nil;
    
    if (height < 1)
    {
        height = 1;
    }
    
    VIMPicture *selectedPicture = [self.pictures lastObject];
    
    for( VIMPicture *picture in self.pictures)
    {
        if (picture.height.floatValue >= height && abs(picture.height.floatValue - height) < abs(selectedPicture.height.floatValue - height))
        {
            selectedPicture = picture;
        }
    }
    
    return selectedPicture;
}

#pragma mark - VIMMappable

- (NSDictionary *)getObjectMapping
{
    return @{@"sizes": @"pictures"};
}

- (Class)getClassForCollectionKey:(NSString *)key
{
    if ( [key isEqualToString:@"sizes"] )
    {
        return [VIMPicture class];
    }
    
    return nil;
}

@end
