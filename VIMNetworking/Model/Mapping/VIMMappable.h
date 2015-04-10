//
//  VIMMappable.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/25/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VIMMappable <NSObject>

@optional

- (id)getObjectMapping;
- (Class)getClassForCollectionKey:(NSString *)key;
- (Class)getClassForObjectKey:(NSString *)key;
- (void)didFinishMapping;

@end
