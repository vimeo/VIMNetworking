//
//  VIMVideoPlayRepresentation.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIMVideoPlayRepresentation : VIMModelObject // Verbose naming since VIMVideoPlay felt too similar to VIMVideoPlayer [NL]

@property (nonatomic, strong, nullable) NSDictionary *hls;
@property (nonatomic, strong, nullable) NSArray *progressive;
@property (nonatomic, strong, nullable) NSNumber *progress;
@property (nonatomic, strong, nullable) NSString *status;

@end
