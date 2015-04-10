//
//  VIMVimeoRequestSerializer.h
//  VIMNetworking
//
//  Created by Kashif Muhammad on 8/27/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import "AFURLRequestSerialization.h"

@class VIMAccount;
@class VIMSession;

@interface VIMRequestSerializer : AFJSONRequestSerializer

+ (instancetype)serializerWithSession:(VIMSession *)session;

- (NSString *)JSONAcceptHeaderString;

@end
