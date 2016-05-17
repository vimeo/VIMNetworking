//
//  VIMVideoPlayRepresentation.h
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMModelObject.h"

@class VIMVideoHLSFile;
@class VIMVideoDASHFile;
@class VIMVideoProgressiveFile;

typedef NS_ENUM(NSUInteger, VIMVideoPlayabilityStatus) {
    VIMVideoPlayabilityStatusUnavailable,   // Not finished transcoding
    VIMVideoPlayabilityStatusPlayable,      // Can be played
    VIMVideoPlayabilityPurchaseRequired,    // On demand video that is not purchased
    VIMVideoPlayabilityRestricted           // User's region cannot play or purchase
};

@interface VIMVideoPlayRepresentation : VIMModelObject

@property (nonatomic, strong, nullable) VIMVideoHLSFile *hlsFile;
@property (nonatomic, strong, nullable) VIMVideoDASHFile *dashFile;
@property (nonatomic, strong, nullable) NSArray<VIMVideoProgressiveFile *> *progressiveFiles;
@property (nonatomic, assign) VIMVideoPlayabilityStatus playabilityStatus;

@end
