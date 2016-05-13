//
//  VIMVideoFileProtocol.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

@import Foundation;

@protocol VIMVideoFileProtocol <NSObject>

@property (nonatomic, copy, nullable) NSString *link;
@property (nonatomic, strong, nullable) VIMVideoLog *log;
@property (nonatomic, strong, nullable) NSDate *expirationDate;

- (BOOL)isExpired;
- (BOOL)isSupportedMimeType;

@end

