# KinveyKit Release History

## 1.10
### 1.10.4
** Release Date:** October 23, 2012

* Minor update(s)

### 1.10.3
** Release Date:** October 18, 2012

* __Change in behavior when saving objects with relationships__.
    * Objects specified as relationships (through `kinveyPropertyToCollectionMapping`) will, by default, __no longer be saved__ to its collection when the owning object is saved. Like before, there will be a reference dictionary saved to the backend in place of the object.
    * If a reference object has not had its `_id` set, either programmatically or by saving that object to the backend, then saving the owning object will fail. The save will not be sent, and the `completionBlock` callback with have an error with an error code: `KCSReferenceNoIdSetError`.
    * To save the reference objects (either to simplify the save or have the backend generate the `_id`'s), have the `KCSPersistable` object implement the `- referenceKinveyPropertiesOfObjectsToSave` method. This will return an array of backend property names for the objects to save. 
        * For example, if you have an `Invitation` object with a reference property `Invitee`, in addition to mentioning the `Invitee` property in `- hostToKinveyPropertyMapping` and `- kinveyPropertyToCollectionMapping`, if you supply `@"Invitee"` in `- referenceKinveyPropertiesOfObjectsToSave`, then any objects in the `Invitee` property will be saved to the backend before saving the `Invitation` object, populating any `_id`'s as necessary.

### 1.10.2
** Release Date:** October 12, 2012

* Improved support for querying relationships through `KCSLinkedAppdataStore` and for using objects in queries
    * Added constants: `KCSMetadataFieldCreator` and `KCSMetadataFieldLastModifiedTime` to `KCSMetadata.h` to allow for querying for entities based on the user that created the object and the last time the entity was updated on the server.
    * Added the ability to use `NSDate` objects in queries, supporting exact matches, greater than (or equal) and less than (or equal) comparisons.
* Added support for establishing references to users:
    * Added constant `KCSUserCollectionName` to allow for adding relationships to user objects from any object's `+kinveyPropertyToCollectionMapping`.
    * Deprecated `- [KCSUser userCollection]` in favor of `+[KCSCollection userCollection]` to create a collection object to the user collection. 
    

### 1.10.1
** Release Date:** October 10, 2012

* Added `+ [KCSUser sendEmailConfirmationForUser:withCompletionBlock:]` in order to send an email confirmation to the user. 

### 1.10.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit1100APIDiffs/KinveyKit1100APIDiffs.html)

** Release Date: ** October 8, 2012

* Added `+ [KCSUser sendPasswordResetForUser:withCompletionBlock:]` in order to send a password reset email to the user.  
* Bug fix(es):
    * Fixed false error when deleting entities using old `KCSCollection` interface.
    * Fixed error when loading dates that did not specify millisecond information. 

## 1.9
### 1.9.1
** Release Date: ** October 2, 2012

* Bug fix(es):
    * `KCSLinkedAppdataStore` now supports relationships when specifying an optional `cachePolicy` when querying. 

### 1.9.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit190APIDiffs/KinveyKit190APIDiffs.html)
** Release Date: ** October 1, 2012

* Added support for log-in with twitter
    * Deprecate Facebook-specific methods and replace with generic social identity. See `KCSUser`.
    * Requires linking Twitter.framework and Accounts.framework.
* Added support for `id<KCSPersistable>` objects to be used as match values in `KCSQuery` when using relationships through `KCSLinkedAppdataStore`.
* Deprecated `KCSEntityDict`. You can now just save/load `NSMutableDictionary` objects directly with the backend. Use them like any other `KCSPersistable`.
    * Note: using a non-mutable `NSDictionary` will not have its fields updated when saving the object.
* Upgraded Urban Airship library to 1.3.3.
* Improved usability for Push Notifications
    * Deprecated `- [KCSPush onLoadHelper:]`; use `- [KCSPush onLoadHelper:error:]` instead to capture set-up errors.

## 1.8
### 1.8.3
** Release Date: ** September 25, 2012

* Bug fix(es):
    * Fix issue with production push.
    * Fix issue with analytics on libraries built with Xcode 4.5.

### 1.8.2
** Release Date: ** September 14, 2012

* Bug fix(es): Fix sporadic crash on restore from background.

### 1.8.1 
** Release Date: ** September 13, 2012

* Added `KCSUniqueNumber` entities to provide monotonically increasing numerical sequences across a collection.

### 1.8.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit180APIDiffs/KinveyKit180APIDiffs.html)
** Release date: ** September 11, 2012

* `KCSLinkedAppdataStore` now supports object relations through saving/loading entities with named fields of other entities.
* Added `kKCSRegex` regular expression querying to `KCSQuery`.
* Added `KCSEntityKeyGeolocation` constant to KinveyPersistable.h as a convience from using the `_geoloc` geo-location field. 
* Added `CLLocation` category methods `- [CLLocation kinveyValue]` and `+ [CLLocation  locationFromKinveyValue:]` to aid in the use of geo data.
* Support for `NSSet`, `NSOrderedSet`, and `NSAttributedString` property types. These are saved as arrays on the backend.  See [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) for more information.
* Support for Kinvey backend API version 2. 
* Documentation Updates.
    * Added [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) Guide.
    * Added links to the api differences to this document.

## 1.7
### 1.7.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit170APIDiffs/KinveyKit170APIDiffs.html)
** Release date: ** Aug 17, 2012

* `KCSCachedStore` now provides the ability to persist saves when the application is offline, and then to save them when the application regains connectivity. See also `KCSOfflineSaveStore`.
* Added login with Facebook to `KCSUser`, allowing you to use a Facebook access token to login in to Kinvey.
* Documentation Updates.
    * Added [Threading Guide](Documents/guides/gcd-guide/Using%20KinveyKit%20with%20GCD.html).
    * Added [Core Data Migration Guide](Documents/guides/using-coredata-guide/KinveyKit%20CoreData%20Guide.html)
* Bug Fix(es).
    * Updated our reachability aliases to make the KinveyKit more compatible with other frameworks. 

## 1.6
### 1.6.1 
** Release Date: ** July 31st, 2012

* Bug Fix(es).
    * Fix issue with hang on no results using `KCSAppdataStore`.

### 1.6.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit160APIDiffs/KinveyKit160APIDiffs.html)
** Release Date: ** July 30th, 2012

* Added `KCSUserDiscovery` to provide a method to lookup other users based upon criteria like name and email address. 
* Upgraded Urban Airship library to 1.2.2.
* Documentation Updates.
    * Added API difference lists for KinveyKit versions 1.4.0, 1.5.0, and 1.6.0
    * Added tutorial for using 3rd Party APIs with OAuth 2.0
* Bug Fix(es).
    * Changed `KCSSortDirection` constants `kKCSAscending` and `kKCSDescending` to sort in the proscribed orders. If you were using the constants as intended, no change is needed. If you swaped them or modified their values to work around the bug, plus update to use the new constants. 

## 1.5

### 1.5.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit150APIDiffs/KinveyKit150APIDiffs.html)
** Release Date: ** July 10th, 2012

* Added `KCSMetadata` for entities to map by `KCSEntityKeyMetadata` in `hostToKinveyPropertyMapping`. This provides metadata about the entity and allows for fine-grained read/write permissions. 
* Added `KCSLinkedAppdataStore` to allow for the saving/loading of `UIImage` properties automatically from our resource service. 

## 1.4

### 1.4.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit140APIDiffs/KinveyKit140APIDiffs.html)
** Release Date: ** June 7th, 2012

* Added`KCSCachedStore` for caching queries to collections. 
* Added aggregation support (`groupBy:`) to `KCSStore` for app data collections. 

## 1.3

### 1.3.1
** Release Date: ** May 7th, 2012

* Fixed defect in Resource Service that prevented downloading resources on older iOS versions (< 5.0)

### 1.3.0
** Release Date: ** April 1st, 2012

* Migrate to using SecureUDID
* General memory handling improvements
* Library now checks reachability prior to making a request and calls failure delegate if Kinvey is not reachable.
* Fixed several known bugs

## 1.2

### 1.2.1
** Release Date: ** Februrary 22, 2012

* Update user-agent string to show correct revision

### 1.2.0
** Release Date: ** Februrary 14, 2012

* Updated query interface (See KCSQuery)
* Support for GeoQueries
* Added features to check-reachability
* Stability improvements
* Documentation improvements

## 1.1

### 1.1.1
** Release Date: ** January 24th, 2012

* Fix namespace collision issues.
* Added support for Core Data (using a designated initializer to build objects)

### 1.1.0
** Release Date: ** January 24th, 2012

* Added support for NSDates
* Added full support for Kinvey Users (See KCSUser)
* Stability improvements

## 1.0

### 1.0.0
** Release Date: ** January 20th, 2012

* Initial release of Kinvey Kit
* Basic support for users, appdata and resources
* Limited release
