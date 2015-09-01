//
//  VIMTaskQueueArchiverProtocol.h
//  Pods
//
//  Created by Hanssen, Alfie on 9/1/15.
//
//

#import <Foundation/Foundation.h>

@protocol VIMTaskQueueArchiverProtocol <NSObject>

@required
- (nullable id)loadObjectForKey:(nonnull NSString *)key;
- (void)saveObject:(nonnull id)object forKey:(nonnull NSString *)key;
- (void)deleteObjectForKey:(nonnull NSString *)key;

@end
