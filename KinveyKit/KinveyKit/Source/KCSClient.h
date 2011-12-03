//
//  KCSClient.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  

#import <Foundation/Foundation.h>

#define MINIMUM_KCS_VERSION_SUPPORTED @"0.6.5"

@class KCSAnalytics;
@class UIApplication;
@class KCSCollection;
@class KCSUser;


// Keys for options hash
#define KCS_APP_KEY_KEY @"kcsAppKey"
#define KCS_APP_SECRET_KEY @"kcsSecret"
#define KCS_BASE_URL_KEY @"kcsBaseUrl"
#define KCS_PORT_KEY @"kcsPortKey"
#define KCS_SERVICE_KEY @"kcsServiceKey"
#define KCS_CONNECTION_TIMEOUT_KEY @"kcsConnectionTimeout"
#define KCS_PUSH_KEY_KEY @"kcsPushKey"
#define KCS_PUSH_SECRET_KEY @"kcsPushSecret"
#define KCS_PUSH_IS_ENABLED_KEY @"kcsPushEnabled"
#define KCS_PUSH_MODE_KEY @"kcsPushMode"
#define KCS_PUSH_DEBUG @"debug"
#define KCS_PUSH_RELEASE @"release"


///*! Interface for a delegate interested in performing an action when a request to the Kinvey Cloud Service Completes.
//
//    Any client that makes a request to the KCS services needs to provided with a delegate which will be notified
//    when the async operations complete.
// */
//@protocol KCSClientActionDelegate <NSObject>
//
///*! Called upon unsuccessful completion of a KCS Request
//    @param error The object representing the failure.
// */
//- (void) actionDidFail: (id)error;
///*! Called upon successful completion of the request
//    @param result The result of the specific action
// */
//- (void) actionDidComplete: (NSObject *) result;
//
//@end

/*! A connection to the Kinvey Cloud Service

    This class is used to represent a connection to the Kinvey service.  It handles all necessary
    authentication and connections to the system, performing all REST actions and notifying completions using
    the @see KCSClientActionDelegate

	@todo: Remove nonatomic property from fields (after verifying atomicity)
 */
@interface KCSClient : NSObject <NSURLConnectionDelegate>

#pragma mark -
#pragma mark Properties


/*! Kinvey provided App Key */
@property (nonatomic, copy, readwrite) NSString *appKey;

/*! App Secret Key provided by Kinvey */
@property (nonatomic, copy, readwrite) NSString *appSecret;

/*! Configuration settings for this client */
@property (nonatomic, retain) NSDictionary *options;

@property (nonatomic, copy, readonly) NSString *userAgent;
@property (nonatomic, copy, readonly) NSString *libraryVersion;
@property (nonatomic, copy) NSURLCredential *authCredentials;

@property (nonatomic, readonly) NSURLCacheStoragePolicy cachePolicy;
@property (nonatomic, copy, readonly) NSString *dataBaseURL;
@property (nonatomic, copy, readonly) NSString *assetBaseURL;
@property (nonatomic, copy, readonly) NSString *userBaseURL;

@property (nonatomic, copy, readonly) NSString *protocol;

@property double connectionTimeout;

@property (nonatomic, retain) KCSUser *currentUser;

/////// D A N G E R -- Always lock before 
@property (nonatomic) BOOL userIsAuthenticated;
@property (nonatomic) BOOL userAuthenticationInProgress;


// Do not expose this to clients yet... soon?
@property (readonly) KCSAnalytics *analytics;

#pragma mark -
#pragma mark Initializers

// Singleton
+ (KCSClient *)sharedClient;

- (KCSClient *)initializeKinveyServiceForAppKey: (NSString *)appKey withAppSecret: (NSString *)appSecret usingOptions: (NSDictionary *)options;

#pragma mark Client Interface

/*! Return the collection object that a specific entity will belong to
 
 @param collection The name of the collection that will contain the objects.
 @returns The collection object.
*/
- (KCSCollection *)collectionFromString: (NSString *)collection;
- (KCSCollection *)collectionFromString: (NSString *)collection withClass: (Class)collectionClass;


@end
