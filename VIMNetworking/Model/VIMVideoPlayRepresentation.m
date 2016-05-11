//
//  VIMVideoPlayRepresentation.m
//  Vimeo
//
//  Created by Lehrer, Nicole on 5/11/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

#import "VIMVideoPlayRepresentation.h"
#import "VIMVideoFile.h"
#import "VIMVideoLog.h"

@implementation VIMVideoPlayRepresentation

- (void) didFinishMapping
{
    //verify HLS worked
    [self parseHLSRepresentation:self.hls];
    
    //verify status worked
    NSLog(@"status is %@", self.status);
    
    /*
    //verify files worked
    for (VIMVideoFile *file in self.progressive)
    {
        NSLog(@"\n");
        NSLog(@"new file: ");
        NSLog(@"expirationDate is %@", file.expirationDate);
        NSLog(@"width is %@", file.width);
        NSLog(@"height is %@", file.height);
        NSLog(@"size is %@", file.size);
        NSLog(@"link is %@", file.link);
        NSLog(@"quaity is %@", file.quality);
        NSLog(@"type is %@", file.type);
        NSLog(@"log.playURLString is %@", file.log.playURLString);
        NSLog(@"log.playURLString is %@", file.log.loadURLString);
        NSLog(@"log.playURLString is %@", file.log.likeURLString);
        NSLog(@"log.playURLString is %@", file.log.watchLaterURLString);
    }
    */
}

- (Class) getClassForObjectKey:(NSString *)key
{
    return nil;
}

- (Class) getClassForCollectionKey:(NSString *)key
{
    if([key isEqualToString:@"progressive"])
    {
        return [VIMVideoFile class];
    }
    return nil;
}

- (void) parseHLSRepresentation:(NSDictionary *)representation
{
    NSString *link = [representation valueForKey:@"link"];
    NSDictionary *log = [representation valueForKey:@"log"];
    
    NSLog(@"HLS link is %@", link);
    NSLog(@"HLS log is %@", log);
}

@end





