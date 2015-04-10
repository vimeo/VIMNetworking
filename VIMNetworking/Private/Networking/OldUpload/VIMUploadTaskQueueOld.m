//
//  VIMUploadManager.m
//  VIMNetworking
//
//  Created by Kashif Mohammad on 20/08/2013.
//  Copyright (c) 2013 Vimeo. All rights reserved.
//

#import "VIMUploadTaskQueueOld.h"

#import "VIMRequestOperationManager.h"
#import "VIMTaskOld.h"
#import "VIMNetworking.h"

@interface VIMUploadTaskQueueOld ()

@property (nonatomic, assign) BOOL useAppGroupCache;

@end

@implementation VIMUploadTaskQueueOld

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (VIMUploadTaskQueueOld *)sharedInstance
{
    static VIMUploadTaskQueueOld *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[VIMUploadTaskQueueOld alloc] initWithName:@"UploadQueue_Shared"];
    });
    
    return _sharedInstance;
}

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name useAppGroupCache:NO];
}

- (instancetype)initWithName:(NSString *)name useAppGroupCache:(BOOL)useAppGroupCache
{
	self = [super initWithName:name];
	if (self)
	{
        _useAppGroupCache = useAppGroupCache;
        
        [self authenticatedUserDidChange:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticatedUserDidChange:) name:VIMSession_AuthenticatedUserDidChangeNotification object:nil];
	}
	
	return self;
}

#pragma mark - Notifications

- (void)authenticatedUserDidChange:(NSNotification *)notification
{
    if(self.useAppGroupCache)
        [self setCache:[[VIMSession sharedSession] appGroupUserCache]];
    else
        [self setCache:[[VIMSession sharedSession] userCache]];
}

@end
