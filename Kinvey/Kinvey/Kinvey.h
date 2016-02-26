//
//  Kinvey.h
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import UIKit;

//! Project version number for Kinvey.
FOUNDATION_EXPORT double KinveyVersionNumber;

//! Project version string for Kinvey.
FOUNDATION_EXPORT const unsigned char KinveyVersionString[];

#import <Kinvey/KNVReadPolicy.h>
#import <Kinvey/KNVRequest.h>
#import <Kinvey/KNVDataStore.h>

// KinveyKit
#import <Kinvey/KCSRealmEntityPersistence.h>
#import <Kinvey/KCSReachability.h>
#import <Kinvey/KCSPush.h>
#import <Kinvey/KCSKeychain.h>
#import <Kinvey/KCSMICLoginViewController.h>
#import <Kinvey/KCSQueryAdapter.h>

// NSPredicate-MongoDB-Adaptor => https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor
#import <Kinvey/MongoDBPredicateAdaptor.h>
