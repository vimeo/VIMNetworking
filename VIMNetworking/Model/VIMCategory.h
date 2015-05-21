//
//  VIMCategory.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/20/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMPictureCollection;
@class VIMConnection;
@class VIMInteraction;

@interface VIMCategory : VIMModelObject

@property (nonatomic, copy) NSString *uri;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, assign) BOOL isTopLevel;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;

- (VIMConnection *)connectionWithName:(NSString *)connectionName;
- (VIMInteraction *)interactionWithName:(NSString *)name;

@end
