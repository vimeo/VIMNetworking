//
//  ActivateRecordTask.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"

@interface VIMActivateTicketTask : VIMNetworkTask

// Output
@property (nonatomic, copy, readonly) NSString *videoURI;

- (instancetype)initWithActivationURI:(NSString *)activationURI;

@end
