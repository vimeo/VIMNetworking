//
//  VIMServerResponseMapper.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 9/19/14.
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

#import "VIMServerResponseMapper.h"
#import "VIMRequestOperation.h"
#import "VIMServerResponse.h"
#import "VIMRequestDescriptor.h"
#import "VIMObjectMapper.h"
#import "VIMMappable.h"

static NSString *const VIMServerResponseMapperErrorDomain = @"VIMServerResponseMapperErrorDomain";

@implementation VIMServerResponseMapper

+ (void)responseFromJSON:(id)JSON operation:(VIMRequestOperation *)operation completionBlock:(VIMServerResponseMapperCompletionBlock)completionBlock
{
    NSDictionary *err = [JSON objectForKey:@"err"];
    if(err != nil && (id)err != (id)[NSNull null])
    {
        int code = [[err objectForKey:@"code"] intValue];
        NSString *expl = [err objectForKey:@"expl"];
        NSString *msg = [err objectForKey:@"msg"];
        
        // TODO: Check for login token expiration error
        if(code == 302)
            NSLog(@"generateResponseFromJSON: error code 302. login token expired.");
        
        NSString *localizedDescription = msg;
        NSString *localizedFailureReason = expl;
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:localizedDescription, NSLocalizedDescriptionKey, localizedFailureReason, NSLocalizedFailureReasonErrorKey, nil];
        
        NSError *error = [NSError errorWithDomain:VIMServerResponseMapperErrorDomain code:code userInfo:errorDict];
        
        if(completionBlock)
            completionBlock(nil, error);
        
        return;
    }
    
    // Create a response object
    
    VIMServerResponse *response = [[VIMServerResponse alloc] init];
    response.request = operation;
    
    id modelParentRoot = JSON;
    
    if(operation.descriptor.modelClass != nil && [operation.descriptor.modelClass conformsToProtocol:@protocol(VIMMappable)])
    {
        // Create mapper and add mappings for appropriate keypaths e.g. @"videos.video"
        
        VIMObjectMapper *mapper = [[VIMObjectMapper alloc] init];
        if(operation.descriptor.modelClass && operation.descriptor.modelKeyPath)
            [mapper addMappingClass:operation.descriptor.modelClass forKeypath:operation.descriptor.modelKeyPath];
        
        // Apply mapping to JSON
        
        id mapperResult = [mapper applyMappingToJSON:JSON];
        
        // Get our objects on expected keypaths
        
        if(operation.descriptor.modelKeyPath && operation.descriptor.modelKeyPath.length > 0)
            response.result = (NSArray *)[mapperResult valueForKeyPath:operation.descriptor.modelKeyPath];
        else
            response.result = mapperResult;
        
        // Find model parent root
        
        NSString *parentKeyPath = @"";
        NSArray *components = [operation.descriptor.modelKeyPath componentsSeparatedByString:@"."];
        if(components)
        {
            for(int i=0;i<components.count-1;i++)
                parentKeyPath = [parentKeyPath stringByAppendingString:[components objectAtIndex:i]];
        }
        
        modelParentRoot = [JSON valueForKeyPath:parentKeyPath];
        
        if(![modelParentRoot isKindOfClass:[NSDictionary class]])
            modelParentRoot = JSON;
    }
    else
    {
        response.result = JSON;
    }
        
    // Get paging information
    
    int page = [[modelParentRoot objectForKey:@"page"] intValue];
    int perpage = [[modelParentRoot objectForKey:@"per_page"] intValue];
    int total = [[modelParentRoot objectForKey:@"total"] intValue];
    
    int totalPages = 0;
    if(perpage != 0)
        totalPages = (int)ceilf( total/(float)perpage );
    
    response.totalResults = total;
    response.totalPages = totalPages;
    response.currentPage = page - 1;
    response.resultsPerPage = perpage;
    
    NSDictionary *paging = [modelParentRoot objectForKey:@"paging"];
    if (paging && [paging isKindOfClass:[NSDictionary class]])
    {
        response.first = [self isNull:paging[@"first"]] ? nil : paging[@"first"];
        response.last = [self isNull:paging[@"last"]] ? nil : paging[@"last"];
        response.next = [self isNull:paging[@"next"]] ? nil : paging[@"next"];
        response.previous = [self isNull:paging[@"previous"]] ? nil : paging[@"previous"];
    }
    
    if (completionBlock)
    {
        completionBlock(response, nil);
    }
}

+ (BOOL)isNull:(id)element
{
    return [element isKindOfClass:[NSNull class]] || [element isEqual:[NSNull null]];
}

@end
