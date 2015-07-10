//
//  VIMServerResponse.h
//  VIMNetworking
//
//  Created by Kashif Mohammad on 5/1/13.
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

#import <Foundation/Foundation.h>

@protocol VIMRequestToken;

@interface VIMServerResponse : NSObject

@property (nonatomic, strong, nullable) id<VIMRequestToken> request;

@property (nonatomic, assign) BOOL isCachedResponse;
@property (nonatomic, assign) BOOL isFinalResponse;

// Result

@property (nonatomic, strong, nullable) NSURLResponse *urlResponse;

@property (nonatomic, strong, nullable) id result;

@property (nonatomic, assign) int totalResults;
@property (nonatomic, assign) int totalPages;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) int resultsPerPage;

// New

@property (nonatomic, copy, nullable) NSString *first;
@property (nonatomic, copy, nullable) NSString *last;
@property (nonatomic, copy, nullable) NSString *next;
@property (nonatomic, copy, nullable) NSString *previous;

@end
