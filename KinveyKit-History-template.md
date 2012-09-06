# KinveyKit Release History

## 1.8
### 1.8.0 [<sub>api diff</sub>](Documents/docs/Documents/releasenotes/General/KinveyKit180APIDiffs/KinveyKit180APIDiffs.html)
** Release date: ** TBD
* Added `kKCSRegex` regular expression querying to `KCSQuery`.
* Added `KCSEntityKeyGeolocation` constant to KinveyPersistable.h as a convience from using the `_geoloc` geo-location field. 
* Added `CLLocation` category methods `- [CLLocation kinveyValue]` and `+ [CLLocation  locationFromKinveyValue:]` to aid in the use of geo data.
* Support for `NSSet`, `NSOrderedSet`, and `NSAttributedString` property types. These are saved as arrays on the backend.  See [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) for more information.
* Support for Kinvey backend API version 2. 
* Documentation Updates.
    * Added [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) Guide.
    * Added links to the api differences to this document.

## 1.7
### 1.7.0 [<sub>api diff</sub>](Documents/docs/Documents/releasenotes/General/KinveyKit170APIDiffs/KinveyKit170APIDiffs.html)
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

### 1.6.0 [<sub>api diff</sub>](Documents/docs/Documents/releasenotes/General/KinveyKit160APIDiffs/KinveyKit160APIDiffs.html)
** Release Date: ** July 30th, 2012

* Added `KCSUserDiscovery` to provide a method to lookup other users based upon criteria like name and email address. 
* Upgraded Urban Airship library to 1.2.2.
* Documentation Updates.
    * Added API difference lists for KinveyKit versions 1.4.0, 1.5.0, and 1.6.0
    * Added tutorial for using 3rd Party APIs with OAuth 2.0
* Bug Fix(es).
    * Changed `KCSSortDirection` constants `kKCSAscending` and `kKCSDescending` to sort in the proscribed orders. If you were using the constants as intended, no change is needed. If you swaped them or modified their values to work around the bug, plus update to use the new constants. 

## 1.5

### 1.5.0 [<sub>api diff</sub>](Documents/docs/Documents/releasenotes/General/KinveyKit150APIDiffs/KinveyKit150APIDiffs.html)
** Release Date: ** July 10th, 2012

* Added `KCSMetadata` for entities to map by `KCSEntityKeyMetadata` in `hostToKinveyPropertyMapping`. This provides metadata about the entity and allows for fine-grained read/write permissions. 
* Added `KCSLinkedAppdataStore` to allow for the saving/loading of `UIImage` properties automatically from our resource service. 

## 1.4

### 1.4.0 [<sub>api diff</sub>](Documents/docs/Documents/releasenotes/General/KinveyKit140APIDiffs/KinveyKit140APIDiffs.html)
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
