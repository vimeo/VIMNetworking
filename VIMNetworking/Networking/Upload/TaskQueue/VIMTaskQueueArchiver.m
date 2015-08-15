//
//  VIMTaskQueueArchiver.m
//  Pods
//
//  Created by Alfred Hanssen on 8/14/15.
//
//

#import "VIMTaskQueueArchiver.h"

static NSString *const ArchiveExtension = @"archive";
static NSString *const TaskQueueDirectory = @"task-queue";

@interface VIMTaskQueueArchiver ()

@property (nonnull, strong) NSString *sharedContainerID;

@end

@implementation VIMTaskQueueArchiver

- (instancetype)initWithSharedContainerID:(NSString *)containerID
{
    NSParameterAssert(containerID);
    
    if (![containerID length])
    {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _sharedContainerID = containerID;
    }
    
    return self;
}

#pragma mark - VIMTaskQueueArchiverProtocol

- (nullable id)loadObjectForKey:(nonnull NSString *)key
{
    if (![key length])
    {
        return nil;
    }
    
    id object = nil;

    NSString *path = [self archivePathForKey:key];

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data)
    {
        @try
        {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        @catch (NSException *exception)
        {
            NSLog(@"VIMTaskQueueArchiver: Exception loading object: %@", exception);
            
            [self deleteObjectForKey:key];
        }
    }
    
    return object;
}

- (void)saveObject:(nonnull id)object forKey:(nonnull NSString *)key
{
    if (!object || ![key length])
    {
        return;
    }

    NSString *path = [self archivePathForKey:key];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    if (!success)
    {
        NSLog(@"VIMTaskQueueArchiver: Error saving object");
    }
}

- (void)deleteObjectForKey:(nonnull NSString *)key
{
    if (![key length])
    {
        return;
    }

    NSString *path = [self archivePathForKey:key];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success)
    {
        NSLog(@"VIMTaskQueueArchiver: Error deleting object: %@", error);
    }
}

#pragma mark - Utilities

- (NSString *)archivePathForKey:(NSString *)key
{
    NSString *basePath = [self archiveDirectory];
    
    NSString *filename = [key stringByAppendingPathExtension:ArchiveExtension];
    
    NSString *path = [basePath stringByAppendingPathComponent:filename];
    
    return path;
}

- (NSString *)archiveDirectory
{
    NSURL *groupURL = nil;
    
    if (self.sharedContainerID)
    {
        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.sharedContainerID];
    }
    
    //#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    //    if ([self.sessionManager.session.configuration respondsToSelector:@selector(sharedContainerIdentifier)])
    //    {
    //        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:self.sessionManager.session.configuration.sharedContainerIdentifier];
    //    }
    //#endif
    
    if (groupURL == nil)
    {
        groupURL = [NSURL URLWithString:NSTemporaryDirectory()]; // TODO: We shouldn't be using temp directory for this [AH]
    }
    
    NSString *groupPath = [[groupURL path] stringByAppendingPathComponent:TaskQueueDirectory];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:groupPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Unable to create export directory: %@", error);
        
        // TODO: This is also a problem, we shouldn't be using temp directory for this, and the directory wont exist [AH]
        
        return [NSTemporaryDirectory() stringByAppendingPathComponent:TaskQueueDirectory];
    }
    
    return groupPath;
}

@end
