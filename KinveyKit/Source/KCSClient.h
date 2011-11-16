//
//  KCSClient.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  

#import <Foundation/Foundation.h>

@class UIApplication;
@class KCSCollection;


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


/*! Interface for a delegate interested in performing an action when a request to the Kinvey Cloud Service Completes.

    Any client that makes a request to the KCS services needs to provided with a delegate which will be notified
    when the async operations complete.
 */
@protocol KCSClientActionDelegate <NSObject>

/*! Called upon unsuccessful completion of a KCS Request
    @param error The object representing the failure.
 */
- (void) actionDidFail: (id)error;
/*! Called upon successful completion of the request
    @param result The result of the specific action
 */
- (void) actionDidComplete: (NSObject *) result;

@end

/*! A connection to the Kinvey Cloud Service

    This class is used to represent a connection to the Kinvey service.  It handles all necessary
    authentication and connections to the system, performing all REST actions and notifying completions using
    the @see KCSClientActionDelegate

	@todo: Remove nonatomic property from fields (after verifying atomicity)
 */
@interface KCSClient : NSObject <NSURLConnectionDelegate>

#pragma mark -
#pragma mark Properties


/*! Stored data in response to a request */
@property (retain) NSMutableData *receivedData;

/*! The (HTTP) response from the server.  We only store the final responding server in a redirect chain */
@property (retain) NSURLResponse *lastResponse;

/*! Kinvey provided App Key */
@property (retain, readwrite) NSString *appKey;

/*! App Secret Key provided by Kinvey */
@property (retain, readwrite) NSString *appSecret;

/*! Base URL for the Kinvey service */
@property (retain) NSString *baseURL;

/*! Stored credentials for Kinvey access */
@property (retain) NSURLCredential *basicAuthCred;

/*! Delegate to inform of completes... @todo This seems broken... */
@property (assign) id <KCSClientActionDelegate> actionDelegate;

/*! How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

/*! Configuration settings for this client */
@property (retain) NSDictionary *options;



#pragma mark -
#pragma mark Initializers

/*! Initialize this class
	@returns The instance of the newly created object.
*/
- (id)init;

/*! Initialize this class with a known app key and secret key
	@param key The Kinvey App Key (can be found in the Kinvey Dashboard)
	@param secret The Kinvey Secret Key (can be found in the Kinvey Dashboard)
	@returns The instance of the newly created object.
*/
- (id)initWithAppKey:(NSString *)key andSecret: (NSString *)secret;

/*! Initialize this class with a known app key, secret key and base URL
	@param key The Kinvey App Key (can be found in the Kinvey Dashboard)
	@param secret The Kinvey Secret Key (can be found in the Kinvey Dashboard)
	@param url The Base URL for this app (can be found in the Kinvey Dashboard)
	@returns The instance of the newly created object.

*/
- (id)initWithAppKey:(NSString *)key andSecret: (NSString *)secret usingBaseURL: (NSString *)url;

/*! Initialize this class with an options dictionary
	@param optionsDictionary A dictionary of configuraiton options
	@returns The instance of the newly created object.

	@sa KinveyOptions
	@todo Document this dictionary
*/
- (id)initWithOptions:(NSDictionary *) kinveyOptions;


#pragma mark push notifications
// PUSH
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)setPushBadgeNumber: (int)number;
- (void)resetPushBadge;

// - (void) exposeSettingsViewInView: (UIViewController *)parentViewController


#pragma mark Client Interface

/*! Return the collection object that a specific entity will belong to
 
 @param collection The name of the collection that will contain the objects.
 @returns The collection object.
*/
- (KCSCollection *)collectionFromString: (NSString *)collection;
- (KCSCollection *)collectionFromString: (NSString *)collection withClass: (Class)collectionClass;


#pragma mark RESTful operations

// This is the rest interface to the client!  Do not use these functions
// unless you know exactly what you're doing!

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param path The FULL path of the resource to GET
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forGetRequestAtPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param putRequest an NSData object containing UTF-8 encoded JSON data
	@param path The FULL path of the resource to PUT
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPutRequest: (NSData *)putRequest atPath: (NSString *)path;

- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDataPutRequest: (NSData *)putRequest atPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param postRequest an NSData object containing UTF-8 encoded JSON data
	@param path The FULL path of the resource to POST
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPostRequest: (NSData *)postRequest atPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param path The FULL path of the resource to DELETE
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDeleteRequestAtPath: (NSString *)path;

@end
