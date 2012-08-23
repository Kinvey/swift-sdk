## Datatypes in KinveyKit
Not all object types are representable in Kinvey's back-end and thus are not saved when specified as a property of a `KCSPersistable` class. In general, only properties of JOSN-compatible types are persistable. This is done to make back-end cross-platform compatible and easy to parse. These considerations are similar to those when using `NSCoding`.

We've also provided built-in converters for common `Foundation` types (as specified in the table below). If you want to support other types, supply a proxy property (as described below). 

## Supported Types Table
Any property of the following classes will be persisted to the backend in the specified type. 

| Objective-C Type | Kinvey (JSON) Backend Type | Notes|
|:-----------------------------------|-------------|----------|
| NSNumber | number  (or `true`/`false` for BOOL)| | 
| NSString | string | |
| NSArray\NSMutableArray | array | return type is always immutable
| NSDictionary\NSMutableDictionary | object | return type is always immutable |
| NSDate | ISO 8601 string | Kinvey string form is: `"ISODate("YYYY-MM-DDThh:mm:ss.sssZ")"`|
| NSSet\NSMutableSet | array ||
| NSOrderedSet\NSMutableOrderedSet | array ||
| NSAttributedString\NSMutableAttributedString | string | Attributes are discarded upon saving; to save the attributes, convert to a persistable representation, such as an html string, or NSDictionary. |
| NSNull | null | |

### Helpers
For some types, we don't want to automatically convert them. This may be due to preventing unintended side-effects, or the object types are less frequently used. 

| Objective-C Type | KinveyKit Helper Methods | Backend Type |
|:---------------|------|--------|
| CLLocation (Core Location) | `- [CLLocation kinveyValue];` <br> `+ [CLLocation  locationFromKinveyValue:kinveyValue]` | array |

### Converting Other Object Types
You can use a proxy type to convert an object to a persistable type. This can be done by using a property that is persistable in `hostToKinveyPropertyMapping` and providing setter/getters that map the non-persistable object. For example, the following code substitutes a `NSArray` for a `CGRect`.

    // RectangleHolder.h
    @interface RectangleHolder : NSObject <KCSPersistable>
    @property (nonatomic) CGRect rect;
    @end
&nbsp;   

    // RectangleHolder.m
    @interface RectangleHolder ()
    @property (nonatomic, assign) NSArray* rectArray;
    @end
    @implementation RectangleHolder
    @synthesize rect;
    - (NSDictionary *)hostToKinveyPropertyMapping {
        return @{ @"rectArray" : @"kinveyRect"};
    }
    - (void) setRectArray:(NSArray *)rectArray {
        self.rect = CGRectMake([[rectArray objectAtIndex:0] floatValue], //x
                               [[rectArray objectAtIndex:1] floatValue], //y
                               [[rectArray objectAtIndex:2] floatValue], //w
                               [[rectArray objectAtIndex:3] floatValue]); //h
    }    
    - (NSArray*) rectArray {
        return @[@(self.rect.origin.x), @(self.rect.origin.y), @(self.rect.size.width), @(self.rect.size.height)];
    }
    @end