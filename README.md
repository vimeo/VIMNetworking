# VIMNetworking

`VIMNetworking` is an Objective-C library that enables interaction with the [Vimeo API](https://developers.vimeo.com).  It handles authentication, request submission, and request cancellation. Advanced features include caching and powerful model object parsing. 

If you'd like to upload videos check out [VIMUpload](https://github.com/vimeo/VIMUpload). 

## Sample Project

Check out the [Pegasus](https://github.com/vimeo/Pegasus) sample project.

## Setup

### Cocoapods

```Ruby
# Add this to your podfile
target 'YourTarget' do
	pod 'VIMNetworking', '5.5.5' # Replace with the latest version
end
```

Note that VIMNetworking has dependencies on `AFNetworking` and `VIMObjectMapper`. They will be imported as pods. 

###Git Submodules

1. Clone the library repo into your Xcode project directory. In terminal:

```
cd your_xcode_project_directory
git clone https://github.com/vimeo/VIMNetworking.git
```
1. Note that VIMNetworking has dependencies on `AFNetworking` and `VIMObjectMapper`. Add these as submodules of VIMNetworking.

1. Locate the `VIMNetworking.xcodeproj` file and add it to your Xcode project. This will add VIMNetworking as a nested subproject. Ensure that the AFNetworking and VIMObjectMapper files are included in the VIMNetworking project. 

1. Link the VIMNetworking static library and its dependencies to your application. Navigate to your app target settings > General > Linked Frameworks and Libraries, and add the following dependencies:

  * `libVIMNetworking.a` 
  * `Social.framework`
  * `Accounts.framework`
  * `MobileCoreServices.framework`
  * `AVFoundation.framework`
  * `SystemConfiguration.framework`

1. Configure Xcode’s header file search path. Navigate to your app target settings > Build Settings.  Under “User Header Search Paths”, add the directory where `VIMNetworking` is located (relative to your project directory: './VIMNetworking/'), and select ‘recursive’.

1. Configure linker settings.  Navigate to Build Settings again.  Under “Other Linker Flags”, add ‘-ObjC’.

1. Add the `digicert-sha2.cer` certificate file to your Xcode project. This can be found in `VIMNetworking/Networking/Certificate/digicert-sha2.cer`. This is necessary to enable certificate pinning. 

## Initialization

On app launch, configure `VIMSession` with your client key, secret, and scope strings. And once initialization is complete, authenticate if necessary.


```Objective-C

#import "VIMNetworking.h"

. . .

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
    config.clientKey = @"your_client_key";
    config.clientSecret = @"your_client_secret";
    config.scope = @"your_scope";
    config.keychainService = @"your_service"; 
    config.keychainAccessGroup = @"your_access_group"; // Optional
    
    [VIMSession sharedSession setupWithConfiguration:config];    

    if ([[VIMSession sharedSession].account isAuthenticated] == NO)
    {
        NSLog(@"Authenticate...");
    }
    else
    {
        NSLog(@"Already authenticated!");
    }

    . . .
}

```

## Authentication 

All calls to the Vimeo API must be [authenticated](https://developer.vimeo.com/api/authentication). This means that before making requests to the API you must authenticate and obtain an access token. Two authentication methods are provided: 

1. [Client credentials grant](https://developer.vimeo.com/api/authentication#unauthenticated-requests): This mechanism allows your application to access publicly accessible content on Vimeo. 

1. [OAuth authorization code grant](https://developer.vimeo.com/api/authentication#generate-redirect): This mechanism allows a Vimeo user to grant permission to your app so that it can access private, user-specific content on their behalf. 

### Client Credentials Grant

```Objective-C
[[VIMSession sharedSession] authenticateWithClientCredentialsGrant:^(NSError *error) {

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
NSURL *URL = [[VIMSession sharedSession].authenticator codeGrantAuthorizationURL];
[[UIApplication sharedApplication] openURL:URL];
```

1. Mobile Safari will open and the user will be presented with a webpage asking them to grant access based on the `scope` that you specified in your `VIMSessionConfiguration` above.  

1. The user is then redirected back to your application. In your `AppDelegate`’s URL handling method, pass the URL back to `VIMAPIClient` to complete the authorization grant:

```Objective-C
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[VIMSession sharedSession] authenticateWithCodeGrantResponseURL:url completionBlock:^(NSError *error) {
        
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

[[VIMSession sharedSession].client requestURI:@"/videos/77091919" completionBlock:^(VIMServerResponse *response, NSError *error) {
	
	id JSONObject = response.result;
	NSLog(@"JSONObject: %@", JSONObject);

}];

```

### Model Object Request

```Objective-C

VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
descriptor.urlPath = @"/videos/77091919";
descriptor.modelClass = [VIMVideo class];

[[VIMSession sharedSession].client requestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {
	
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

[[VIMSession sharedSession].client requestDescriptor:descriptor completionBlock:^(VIMServerResponse *response, NSError *error) {

	NSArray *videos = (NSArray *)response.result; 
	NSLog(@"Array of VIMVideo objects: %@", videos);

}];

```

### Caching Behavior

```Objective-C

VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
descriptor.urlPath = @"/videos/77091919";
descriptor.modelClass = [VIMVideo class];
descriptor.cachePolicy = VIMCachePolicy_NetworkOnly; // Or VIMCachePolicy_LocalOnly etc.
descriptor.shouldCacheResponse = NO; // Defaults to YES

...

// See VIMRequestDescriptor.h/m additional request configuration options

```

### Request Cancellation

```Objective-C

id<VIMRequestToken> currentRequest = [[VIMSession sharedSession].client requestURI:@"/videos/77091919" completionBlock:^(VIMServerResponse *response, NSError *error) {

	id JSONObject = response.result;
	NSLog(@"JSONObject: %@", JSONObject);

}];

[[VIMSession sharedSession].client cancelRequest:currentRequest];

// or

[[VIMSession sharedSession].client cancelAllRequests];

```

## Lightweight Use

If you want to use your own OAuth token you can circumvent `VIMSession` and its authentication mechanisms and make requests like so:

```Objective-C

VIMClient *client = [[VIMClient alloc] initWithDefaultBaseURL];
client.requestSerializer = ...

// Where client.requestSerializer is an AFJSONRequestSerializer subclass that sets the following information for each request:
// [serializer setValue:@"application/vnd.vimeo.*+json; version=3.2" forHTTPHeaderField:@"Accept"];
// [serializer setValue:@"Bearer your_oauth_token" forHTTPHeaderField:@"Authorization"];

[client requestURI:@"/videos/77091919" completionBlock:^(VIMServerResponse *response, NSError *error)
{

    id JSONObject = response.result;
    NSLog(@"JSONObject: %@", JSONObject);

}];

```

### Caching

If you'd like to turn on caching for this lighter weight use case: 

```Objective-C
VIMClient *client = [[VIMClient alloc] initWithDefaultBaseURL];
client.cache = VIMCache *cache = [VIMCache sharedCache];
// Or client.cache = VIMCache *cache = [[VIMCache alloc] initWithName:@"your_cache_name"];

```

## License

`VIMNetworking` is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
