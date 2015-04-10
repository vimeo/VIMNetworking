//
//  VIMObjectMapper.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 3/25/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMObjectMapping;

@interface VIMObjectMapper : NSObject

- (void)addMappingClass:(Class)mappingClass forKeypath:(NSString *)keypath;

- (id)applyMappingToJSON:(id)JSON;

@end
