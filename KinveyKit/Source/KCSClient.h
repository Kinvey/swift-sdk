//
//  KCSClient.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  

#import <Foundation/Foundation.h>
#import "JSONKit.h"

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
@property (retain, nonatomic) NSMutableData *receivedData;

/*! Kinvey provided App Key */
@property (retain, nonatomic, readwrite) NSString *appKey;

/*! App Secret Key provided by Kinvey */
@property (retain, nonatomic, readwrite) NSString *appSecret;

/*! Base URL for the Kinvey service */
@property (retain, nonatomic) NSString *baseURI;

/*! Stored credentials for Kinvey access */
@property (retain, nonatomic) NSURLCredential *basicAuthCred;

/*! Delegate to inform of completes... @todo This seems broken... */
@property (assign) id <KCSClientActionDelegate> actionDelegate;

/*! How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

/*! Configuration settings for this client */
@property (retain) NSDictionary *options;



#pragma mark -
#pragma mark NSURLConnectionDelegate Implementation

// NB: These are implemented only for the purpose of conforming the the
// NSURLConnectionDelegate protocol.  I'm not documenting them for clients
// at this time, since they shouldn't be called by a client.
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;

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

	@todo Rename URI to URL

*/
- (id)initWithAppKey:(NSString *)key andSecret: (NSString *)secret usingBaseURI: (NSString *)uri;

/*! Initialize this class with an options dictionary
	@param optionsDictionary A dictionary of configuraiton options
	@returns The instance of the newly created object.

	@sa KinveyOptions
	@todo Document this dictionary
*/
- (id)initWithOptions:(NSDictionary *)optionsDictionary;


// GET, PUT, POST, DELETE

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param path The path of the resource to GET
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forGetRequestAtPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param putRequest an NSData object containing UTF-8 encoded JSON data
	@param path The path of the resource to PUT
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPutRequest: (NSData *)putRequest atPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param postRequest an NSData object containing UTF-8 encoded JSON data
	@param path The path of the resource to POST
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPostRequest: (NSData *)postRequest atPath: (NSString *)path;

/*! Perform a GET request against the Kinvey Server
	@param delegate The delegate to inform about the result of the request
	@param path The path of the resource to DELETE
	@note The PATH paramter will be appended to the base URL to form the complete URL.
*/
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDeleteRequestAtPath: (NSString *)path;

@end
