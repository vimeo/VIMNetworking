# VIMObjectMapper

`VIMObjectMapper` converts JSON into model objects.

## Usage

### Subclass VIMModelObject

Make your custom model object a subclass of `VIMModelObject` and optionally implement the `VIMMappable` protocol methods:

```Objective-C
#import "VIMModelObject.h"

@class VIMPictureCollection;

@interface VIMUser : VIMModelObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) VIMPictureCollection *pictureCollection;
@property (nonatomic, strong) NSDictionary *uploadQuota;
@property (nonatomic, strong) NSArray *websites;

@end
```
```Objective-C
#import "VIMUser.h"
#import "VIMPictureCollection.h"
#import "VIMObjectMapper.h"

@implementation VIMUser

#pragma mark - VIMMappable // All methods are optional, implement to specify how the object should be "inflated"

- (NSDictionary *)getObjectMapping
{
	return @{@"pictures": @"pictureCollection"};
}

- (Class)getClassForCollectionKey:(NSString *)key
{
    if ([key isEqualToString:@"uploadQuota"])
    {
        return [NSDictionary class];
    }
    
    if ([key isEqualToString:@"websites"])
    {
        return [NSArray class];
    }

    return nil;
}

- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"pictures"])
    {
        return [VIMPictureCollection class];
    }
    
    return nil;
}

- (void)didFinishMapping
{
    // Do any post-parsing work you might want to do
}
```
### Get some JSON

```Objective-C
{
    user = {
        name = "Homer Simpson";
        pictures = {
            uri = "...";
            sizes = (...);
        };
        "upload_quota" = { ... };
        websites = ( ... );
    };
}
```

### Let VIMObjectMapper go to work

```Objective-C
NSDictionary *JSON = ...;

VIMObjectMapper *mapper = [[VIMObjectMapper alloc] init];

[mapper addMappingClass:[VIMUser class] forKeypath:@"user"];

VIMUser *user = [mapper applyMappingToJSON:JSON];
```

## License

`VIMObjectMapper` is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
