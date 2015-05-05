# VIMNetworking

`VIMNetworking` is an Objective-C library that enables interaction with the [Vimeo API](https://developers.vimeo.com).  It handles authentication, request submission and cancellation, and video upload. Advanced features include caching and powerful model object parsing. 

The upload system supports background session uploads from apps and extensions. Its core component is a serial task queue that can execute composite tasks (tasks with subtasks). For example, a composite task might include 3 steps: (1) a video file upload step, (2) a `POST` request to set file metadata (title, description, privacy), and (3) a `POST` request to share the video with friends. The upload system allows users to upload videos to Vimeo, but can be repurposed to manage background upload (or download) from any source. See detailed documentation below for more information. 

## Sample Project

Check out the sample project [here](https://github.com/vimeo/Pegasus).

## Project Setup

1. Clone the library repo into your Xcode project directory. In terminal:

```
cd your_xcode_project_directory
git clone --recursive https://github.com/vimeo/VIMNetworking.git
```

1. Locate the `VIMNetworking.xcodeproj` file and add it to your Xcode project. This will add VIMNetworking as a nested subproject.

1. Link the VIMNetworking static library and its dependencies to your application. Navigate to your app target settings > General > Linked Frameworks and Libraries, and add the following dependencies:

  * `libVIMNetworking.a` 
  * `Social.framework`
  * `Accounts.framework`
  * `MobileCoreServices.framework`
  * `AVFoundation.framework`
  * `SystemConfiguration.framework`

1. Configure Xcode’s header file search path. Navigate to your app target settings > Build Settings.  Under “User Header Search Paths”, add the directory where `VIMNetworking` is located (relative to your project directory: './VIMNetworking/'), and select ‘recursive’.

1. Configure linker settings.  Navigate to Build Settings again.  Under “Other Linker Flags”, add ‘-ObjC’.

1. Add the `vimeo-api-root.cer` certificate file to your Xcode project. This can be found in `VIMNetworking/Networking/Certificate/vimeo-api-root.cer`. This is necessary to enable certificate pinning. 

## Initialization

On app launch, configure `VIMSession` with your client key, secret, and scope strings.

```Objective-C

#import "VIMNetworking.h"

. . .

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
    config.clientKey = @"your_client_key";
    config.clientSecret = @"your_client_secret";
    config.scope = @"private public create edit delete interact";
    
    [[VIMSession sharedSession] setupWithConfiguration:config completionBlock:^(BOOL success) {
    	
    	NSLog(@"VIMSession setup success? %d", success);
    
    }];
    
    // Alternatively, pass a nil completionBlock and subscribe to the VIMSession_DidFinishLoadingNotification

    . . .
}

```

Once initialization is complete, authenticate if necessary:

```Objective-C
NSLog(@"VIMSession setup success? %d", success);

if ([[VIMSession sharedSession].account isAuthenticated] == NO)
{
	NSLog(@"Authenticate...");
}
else
{
	NSLog(@"Already authenticated!");
}
```

## Authentication 

All calls to the Vimeo API must be [authenticated](https://developer.vimeo.com/api/authentication). This means that before making requests to the API you must authenticate and obtain an access token. Two authentication methods are provided: 

1. [Client credentials grant](https://developer.vimeo.com/api/authentication#unauthenticated-requests): This mechanism allows your application to access publicly accessible content on Vimeo. 

1. [OAuth authorization code grant](https://developer.vimeo.com/api/authentication#generate-redirect): This mechanism allows a Vimeo user to grant permission to your app so that it can access private, user-specific content on their behalf. 

### Client Credentials Grant

```Objective-C
[[VIMAPIClient sharedClient] authenticateWithClientCredentialsGrant:^(NSError *error) {

        if (error == nil)
        {
            NSLog(@"Success!");
        }
        else
        {
            NSLog(@"Failure: %@", error);
        }
        
}];

```

### OAuth Authorization Code Grant

1. Set up a redirect url scheme:

Navigate to your app target settings > Info > URL Types.  Add a new URL Type, and under url scheme enter `vimeo{CLIENT_KEY}` (ex: if your CLIENT_KEY is `1234`, enter `vimeo1234`).  This allows Vimeo to redirect back into your app after authorization.  

You also need to add this redirect URL to your app on the Vimeo API site.  Under “App Callback URL”, add `vimeo{CLIENT_KEY}://auth` (for the example above, `vimeo1234://auth`).

1. Open the authorization URL in Mobile Safari: 

```Objective-C
NSURL *URL = [[VIMAPIClient sharedClient] codeGrantAuthorizationURL];
[[UIApplication sharedApplication] openURL:URL];
```

1. Mobile Safari will open and the user will be presented with a webpage asking them to grant access based on the `scope` that you specified in your `VIMSessionConfiguration` above.  

1. The user is then redirected back to your application. In your `AppDelegate`’s URL handling method, pass the URL back to `VIMAPIClient` to complete the authorization grant:

```Objective-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[VIMAPIClient sharedClient] authenticateWithCodeGrantResponseURL:url completionBlock:^(NSError *error) {
        
        if (error == nil)
        {
            NSLog(@"Success!");
        }
        else
        {
            NSLog(@"Failure: %@", error);
        }

    }];
    
    return YES;
}
```

## Requests

With `VIMNetworking` configured and authenticated, you’re ready to start making requests to the Vimeo API.

### JSON Request

```Objective-C

[[VIMAPIClient sharedClient] fetchWithURI:@"/videos/77091919" completionBlock:^(VIMServerResponse *response, NSError *error) {
	
	id JSONObject = response.result;
	NSLog(@"JSONObject: %@", JSONObject);

}];

```

### Model Object Request

```Objective-C

VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
descriptor.urlPath = @"/videos/77091919";
descriptor.modelClass = [VIMVideo class];

[[VIMAPIClient sharedClient] fetchWithRequestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {
	
	VIMVideo *video = (VIMVideo *)response.result;
	NSLog(@"VIMVideo object: %@", video);

}];

```

### Collection Request

```Objective-C

VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
descriptor.urlPath = @"/me/videos";
descriptor.modelClass = [VIMVideo class];
descriptor.modelKeyPath = @"data";

[[VIMAPIClient sharedClient] fetchWithRequestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {

	NSArray *videos = (NSArray *)response.result; 
	NSLog(@"Array of VIMVideo objects: %@", videos);

}];

```

### Request Cancellation

```Objective-C

id<VIMRequestToken> currentRequest = [[VIMAPIClient sharedClient] fetchWithURI:@"/videos/77091919" completionBlock:^(VIMServerResponse *response, NSError *error) {

	id JSONObject = response.result;
	NSLog(@"JSONObject: %@", JSONObject);

}];

[[VIMAPIClient sharedClient] cancelRequest:currentRequest];

// or

[[VIMAPIClient sharedClient] cancelAllRequests];

```

## Video Upload

The video upload system uses a background configured NSURLSession to manage a queue of video uploads (i.e. uploads continue regardless of whether the app is in the foreground or background). 

The upload queue can be paused and resumed, and is automatically paused/resumed when losing/gaining a connection. It can also be configured to restrict uploads to wifi only. 

The queue is persisted to disk so that in the event of an app termination event it can be reconstructed to the state it was in before termination. 

When you configure VIMNetworking, set the `backgroundSessionIdentifierApp` property and include the "upload" permission in your scope. If you plan to initiate uploads from an extension, set the `backgroundSessionIdentifierExtension` and `sharedContainerID` properties as well.

```Obejctive-C
VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
config.clientKey = @"your_client_key";
config.clientSecret = @"your_client_secret";
config.scope = @"private public create edit delete interact upload";
config.backgroundSessionIdentifierApp = @"your_app_background_session_id";
config.backgroundSessionIdentifierExtension = @"your_extension_background_session_id";
config.sharedContainerID = @"your_shared_container_id";
```

Load the `VIMUploadTaskQueue`(s) at each launch.

```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...

    [VIMUploadTaskQueue sharedAppQueue];
    [VIMUploadTaskQueue sharedExtensionQueue];

    return YES;
}
```

Implement the `application:andleEventsForBackgroundURLSession:completionHandler:` method in your AppDelegate:

```Objective-C
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:BackgroundSessionIdentifierApp])
    {
        [VIMUploadSessionManager sharedAppInstance].completionHandler = completionHandler;
    }
    else if ([identifier isEqualToString:BackgroundSessionIdentifierExtension])
    {
        [VIMUploadSessionManager sharedExtensionInstance].completionHandler = completionHandler;
    }
}
```

Enqueue a `PHAsset` for upload.

```Objective-C
PHAsset *asset = ...;
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithPHAsset:asset];
[[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue an `AVURLAsset` for upload.

```Objective-C
NSURL *URL = ...;
AVURLAsset *URLAsset = [AVURLAsset assetWithURL:URL];
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithURLAsset:URLAsset];
[[VIMUploadTaskQueue sharedExtensionQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue multiple assets for upload.

```Objective-C
NSArray *videoAssets = @[...];
[[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:videoAssets];
```

Cancel an upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;
[[VIMUploadTaskQueue sharedAppQueue] cancelUploadForVideoAsset:videoAsset];
```

Cancel all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] cancelAllUploads];
```

Pause all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] pause];
```

Resume all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] resume];
```

Ensure that uploads only occur when connected via wifi...or not. If `cellularUploadEnabled` is set to `NO`, the upload queue will automatically pause when leaving wifi and automatically resume when entering wifi. (Note: the queue will automatically pause/resume when the device is taken offline/online.)

```Objective-C
[VIMUploadTaskQueue sharedAppQueue].cellularUploadEnabled = NO;
```

Add video metadata to an enqueued or in-progress upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;

VIMVideoMetadata *videoMetadata = [[VIMVideoMetadata alloc] init];
videoMetadata.videoTitle = @"Really cool title";
videoMetadata.videoDescription = @"Really cool description"";
videoMetadata.videoPrivacy = (NSString *)VIMPrivacyValue_Private;

[[VIMUploadTaskQueue sharedAppQueue] addMetadata:videoMetadata toVideoAsset:videoAsset withCompletionBlock:^(BOOL didAdd) {
    
    if (!didAdd)
    {
        // The upload has already finished, 
        // Set the metadata using the VIMAPIClient method updateVideoWithURI:title:description:privacy:completionHandler:
    }
    
}];
```

If you build UI to support pause and resume, listen for the `VIMNetworkTaskQueue_DidSuspendOrResumeNotification` notification and update your UI accordingly.

```Objective-C
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskQueueDidSuspendOrResume:) name:VIMNetworkTaskQueue_DidSuspendOrResumeNotification object:nil];
}

- (void)uploadTaskQueueDidSuspendOrResume:(NSNotification *)notification
{
    BOOL isSuspended = [[VIMUploadTaskQueue sharedAppQueue] isSuspended];
    [self.pauseResumeButton setSelected:isSuspended];
}
```

Use KVO to communicate upload state and upload progress via your UI. Observe changes to `VIMVideoAsset`'s `uploadState` and `uploadProgressFraction` properties.

```Objective-C
static void *UploadStateContext = &UploadStateContext;
static void *UploadProgressContext = &UploadProgressContext;

- (void)addObservers
{
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
    
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];
}

- (void)removeObservers
{
    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) context:UploadStateContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }

    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) context:UploadProgressContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadStateContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadState))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadStateDidChange];
            });
        }
    }
    else if (context == UploadProgressContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadProgressFraction))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadProgressDidChange];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

When your UI is loaded or refreshed, associate your newly create VIMVideoAsset objects with their upload task counterparts so your UI continues to communicate upload state and progress.

```Objective-C
NSArray *videoAssets = self.datasource.items; // For example
[[VIMUploadTaskQueue sharedAppQueue] associateVideoAssetsWithUploads:videoAssets];
```

###Repurposing the Upload System

The upload system can be repurposed to manage background uploads (or downloads) from any source. The simplest way to do this is to subclass `VIMNetworkTask` and `VIMNetworkTaskQueue`, using `VIMUploadTask` and `VIMUploadTaskQueue` for inspiration. 

## License

`VIMNetworking` is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
