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

/*! A Singleton Class that provides access to all Kinvey Services.

 This class provides a single interface to most Kinvey services.  It provides access to User Servies, Collection services
 (needed to both fetch and save data), Resource Services and Push Services.
 
 @warning Note that this class is a singleton and the single method to get the instance is @see sharedClient.

 */
@interface KCSClient : NSObject <NSURLConnectionDelegate>

#pragma mark -
#pragma mark Properties

///---------------------------------------------------------------------------------------
/// @name Application Information
///---------------------------------------------------------------------------------------
/*! Kinvey provided App Key, set via @see initializeKinveyServiceForAppKey:withAppSecret:usingOptions */
@property (nonatomic, copy, readonly) NSString *appKey;

/*! Kinvey provided App Secret, set via @see initializeKinveyServiceForAppKey:withAppSecret:usingOptions */
@property (nonatomic, copy, readonly) NSString *appSecret;

/*! Configuration options, set via @see initializeKinveyServiceForAppKey:withAppSecret:usingOptions */
@property (nonatomic, retain, readonly) NSDictionary *options;

///---------------------------------------------------------------------------------------
/// @name Library Information
///---------------------------------------------------------------------------------------
/*! User Agent string returned to Kinvey (used automatically, provided for reference. */
@property (nonatomic, copy, readonly) NSString *userAgent;

/*! Library Version string returned to Kinvey (used automatically, provided for reference. */
@property (nonatomic, copy, readonly) NSString *libraryVersion;

///---------------------------------------------------------------------------------------
/// @name Kinvey Service URL Access
///---------------------------------------------------------------------------------------
/*! Base URL for Kinvey data service */
@property (nonatomic, copy, readonly) NSString *dataBaseURL;

/*! Base URL for Kinvey Resource Service */
@property (nonatomic, copy, readonly) NSString *resourceBaseURL;

/*! Base URL for Kinvey User Service */
@property (nonatomic, copy, readonly) NSString *userBaseURL;

///---------------------------------------------------------------------------------------
/// @name Connection Properties
///---------------------------------------------------------------------------------------
/*! Protocol used to connection to Kinvey Service (nominally HTTPS)*/
@property (nonatomic, copy, readonly) NSString *protocol;

/*! Connection Timeout value, set this to cause shorter or longer network timeouts. */
@property double connectionTimeout;

/*! Current Kinvey Cacheing policy */
@property (nonatomic, readonly) NSURLCacheStoragePolicy cachePolicy;


///---------------------------------------------------------------------------------------
/// @name User Authentication
///---------------------------------------------------------------------------------------
/*! Current Kinvey User */
@property (nonatomic, retain) KCSUser *currentUser;
/*! Has the current user been authenticated?  (NOTE: Thread Safe) */
@property (nonatomic) BOOL userIsAuthenticated;
/*! Is user authentication in progress?  (NOTE: Thread Safe, can be used to spin for completion) */
@property (nonatomic) BOOL userAuthenticationInProgress;
/*! Stored authentication credentials */
@property (nonatomic, copy) NSURLCredential *authCredentials;



// Do not expose this to clients yet... soon?

/*! The suite of Kinvey Analytics Services */
///---------------------------------------------------------------------------------------
/// @name Analytics
///---------------------------------------------------------------------------------------
@property (readonly) KCSAnalytics *analytics;

#pragma mark -
#pragma mark Initializers

// Singleton
///---------------------------------------------------------------------------------------
/// @name Accessing the Singleton
///---------------------------------------------------------------------------------------
/*! Return the instance of the singleton.  (NOTE: Thread Safe)
 
 This routine will give you access to all the Kinvey Services by returning the Singleton KCSClient that
 can be used for all client needs.
 
 @returns The instance of the singleton client.
 
 */
+ (KCSClient *)sharedClient;

///---------------------------------------------------------------------------------------
/// @name Initializing the Singleton
///---------------------------------------------------------------------------------------
/*! Initialize the singleton KCSClient with this applications key and the secret for this app, along with any needed options.
 
 This routine MUST be called prior to using the Kinvey Service otherwise all access will fail.  This routine authenticates you with
 the Kinvey Service.  The appKey and appSecret are available in the Kinvey Console.  Options can be used to configure push, etc.
 
 @bug Options array is required for Push, but not yet documented.
 
 @param appKey The Kinvey provided App Key used to identify this application
 @param appSecret The Kinvey provided App Secret used to authenticate this application.
 @param options The NSDictionary used to configure optional services.
 @returns The KCSClient singleton (can be used to chain several calls)
 
 For example, KCSClient *client = [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"key" withAppSecret:@"secret" usingOptions:nil];
 
 */
- (KCSClient *)initializeKinveyServiceForAppKey: (NSString *)appKey withAppSecret: (NSString *)appSecret usingOptions: (NSDictionary *)options;

#pragma mark Client Interface

///---------------------------------------------------------------------------------------
/// @name Collection Interface
///---------------------------------------------------------------------------------------
/*! Return the collection object that a specific entity will belong to
 
 All acess to data items stored on Kinvey must use a collection, to get access to a collection, use this routine to gain access to a collection.
 Simply provide a name and the class of an object that you want to store and you'll be returned the collection object to use.
 
 @param collection The name of the collection that will contain the objects.
 @param collectionClass A class that represents the objects of this collection.
 @returns The collection object.
 
 
*/
- (KCSCollection *)collectionFromString: (NSString *)collection withClass: (Class)collectionClass;


@end
