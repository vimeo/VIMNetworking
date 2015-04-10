//
//  VIMServerResponse.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 5/1/13.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VIMRequestToken;

@interface VIMServerResponse : NSObject

@property (nonatomic, strong) id<VIMRequestToken> request;

@property (nonatomic, assign) BOOL isCachedResponse;
@property (nonatomic, assign) BOOL isFinalResponse;

// Result

@property (nonatomic, strong) NSURLResponse *urlResponse;

@property (nonatomic, strong) id result;

@property (nonatomic, assign) int totalResults;
@property (nonatomic, assign) int totalPages;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) int resultsPerPage;

// New

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *next;
@property (nonatomic, copy) NSString *previous;

@end
