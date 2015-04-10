//
//  CreateRecordTask.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/27/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

#import "VIMNetworkTask.h"

@interface VIMCreateTicketTask : VIMNetworkTask

// Output
@property (nonatomic, copy, readonly) NSString *localURI; // TODO: possible to eliminate this? [AH]
@property (nonatomic, copy, readonly) NSString *uploadURI;
@property (nonatomic, copy, readonly) NSString *activationURI;

@end
