//
//  VIMVideo+VOD.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideo+VOD.h"

@implementation VIMVideo (VOD)

#pragma mark - Public API

- (BOOL)isVOD
{
    return [self vodContainerURI] != nil;
}

- (BOOL)isVODTrailer
{
    return [self isVOD] && [self vodTrailerURI] == nil; // If video lacks a trailer connection, it IS a trailer [NL] 05/22/16
}

- (NSString *)vodTrailerURI
{
    VIMConnection *vodTrailer = [self connectionWithName:VIMConnectionNameVODTrailer];
    
    return vodTrailer.uri;
}

- (NSString *)vodContainerURI
{
    VIMConnection *vodContainer = [self connectionWithName:VIMConnectionNameVODContainer];
    
    return vodContainer.uri;
}

- (VIMVideoVODAccess)vodAccess  
{
    VIMInteraction *buyInteraction = [self interactionWithName:VIMInteractionNameBuy];
    if (buyInteraction.streamStatus == VIMInteractionStreamStatusPurchased)
    {
        return VIMVideoVODAccessBought;
    }
    
    VIMInteraction *rentInteraction = [self interactionWithName:VIMInteractionNameRent];
    if (rentInteraction.streamStatus == VIMInteractionStreamStatusPurchased)
    {
        return VIMVideoVODAccessRented;
    }
    
    VIMInteraction *subscribeInteraction = [self interactionWithName:VIMInteractionNameSubscribe];
    if (subscribeInteraction.streamStatus == VIMInteractionStreamStatusPurchased)
    {
        return VIMVideoVODAccessSubscribed;
    }
    
    return VIMVideoVODAccessUnavailable;
}

- (NSDate *)expirationDateForAccess:(VIMVideoVODAccess)access
{
    if (access == VIMVideoVODAccessRented)
    {
        VIMInteraction *rentInteraction = [self interactionWithName:VIMInteractionNameRent];
        return rentInteraction.expirationDate;
    }
    
    if (access == VIMVideoVODAccessSubscribed)
    {
        VIMInteraction *subscribeInteraction = [self interactionWithName:VIMInteractionNameSubscribe];
        return subscribeInteraction.expirationDate;
    }
    
    return nil;
}

@end
