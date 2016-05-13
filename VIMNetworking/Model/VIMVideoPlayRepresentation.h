//
//  VIMVideoPlayRepresentation.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMVideoHLSFile;

@interface VIMVideoPlayRepresentation : VIMModelObject

@property (nonatomic, strong, nullable) VIMVideoHLSFile *hlsFile;
@property (nonatomic, strong, nullable) NSArray *progressiveFiles; // array of VIMVideoProgressiveFile's
@property (nonatomic, strong, nullable) NSString *status;

@end
