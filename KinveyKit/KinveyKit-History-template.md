# KinveyKit Release History

## 1.4

### 1.4.0
** Release Date: ** June 7th, 2012

* Added`KCSCachedStore` for caching queries to collections. 
* Added aggregation support (`groupBy:`) to `KCSAppdataStore` for app data collections. 

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
