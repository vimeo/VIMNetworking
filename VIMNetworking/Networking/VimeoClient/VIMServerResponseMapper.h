//
//  VIMServerResponseMapper.h
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
//  Copyright (c) 2014 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VIMServerResponse;
@class VIMRequestOperation;

typedef void (^VIMServerResponseMapperCompletionBlock)(VIMServerResponse *response, NSError *error);

@interface VIMServerResponseMapper : NSObject

+ (void)responseFromJSON:(id)JSON operation:(VIMRequestOperation *)operation completionBlock:(VIMServerResponseMapperCompletionBlock)completionBlock;

@end
