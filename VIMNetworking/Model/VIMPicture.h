//
//  VIMPicture.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 5/31/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@interface VIMPicture : VIMModelObject

@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *type;

@end
