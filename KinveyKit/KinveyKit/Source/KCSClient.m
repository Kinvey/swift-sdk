//
//  KinveyClient.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//


#import "KCSClient.h"
#import "JSONKit.h"

#ifndef NO_URBAN_AIRSHIP_PUSH
#import "UAirship.h"
#import "UAPush.h"
#endif

#import "KinveyCollection.h"
#import "KinveyAnalytics.h"
#import "NSURL+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"

#define KCS_JSON_TYPE @"application/json"
#define KCS_DATA_TYPE @"application/octet-stream"

// Anonymous category on KCSClient, used to allow us to redeclare readonly properties
// readwrite.  This keeps KVO notation, while allowing private mutability.
@interface KCSClient ()
    // Redeclare private iVars
    @property double connectionTimeout;

    // Do not expose this to clients yet... soon?
    @property (retain) KCSAnalytics *analytics;
@end

@implementation KCSClient

@synthesize receivedData;
@synthesize lastResponse=_lastResponse;
@synthesize appKey;
@synthesize appSecret;
@synthesize baseURL=_baseURL;
@synthesize basicAuthCred;
@synthesize actionDelegate;
@synthesize connectionTimeout;
@synthesize options=_options;

@synthesize analytics=_analytics;


#pragma mark NSURLConnection Delegates

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // This should be more robust
    NSLog(@"TRACE: connection:canAuthenticateAgainstProtectionSpace:");
    return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // TBD -- Can this happen with a basic auth requestP
    NSLog(@"TRACE: connection:didCancelAuthenticationChallenge:");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"TRACE: connection:didFailWithError:");

    if ([actionDelegate respondsToSelector: @selector(actionDidFail:)]){
        [actionDelegate actionDidFail:error];
    } else {
        NSLog(@"Delegate (%@) does not respond to actionDidFail", actionDelegate);
    }

    // Free the current connection, it's not valid any longer
    [connection release];
    
    // Free our connection data
//    [receivedData release];
    
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);

    

}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"TRACE: connection:didReceiveAuthenticationChallenge:");
    [[challenge sender] useCredential:basicAuthCred forAuthenticationChallenge:challenge]; 
    
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"TRACE: connection:willSendRequestForAuthenticationChallenge");
    [[challenge sender] useCredential:basicAuthCred forAuthenticationChallenge:challenge]; 
    
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    NSLog(@"TRACE: connectionShouldUseCredentialStorage:");
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"TRACE: connection:didReceiveResponse:");
    
    // Store this response, after possibly releasing the last response
    [_lastResponse release]; // Initialized to nil, so this does nothing if we don't have a last response
    [self setLastResponse:response];
    
    NSLog(@"Got response, status code: %d, response: %@", [(NSHTTPURLResponse *)response statusCode], response);
    
    // Make sure to keep the reference around
    [[self lastResponse] retain];
    
    // Reset any connection specific properties, begin logging new connection data
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"TRACE: connection:didReceiveData:");
    // Each time we get more data just appened it to the end
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSLog(@"TRACE: connectionDidFinishLoading:");
    NSLog(@"Success! Received %u bytes: ", [receivedData length]);
    NSDictionary *jsonData = [receivedData objectFromJSONData];
    NSLog(@"JSON Data: %@", jsonData);
    if ( [actionDelegate respondsToSelector:@selector(actionDidComplete:)] ) {
            [actionDelegate actionDidComplete:receivedData];
    } else {
        NSLog(@"Delegate (%@) does not respond to actionDidComplete", actionDelegate);
    }

    [connection release];
//    [receivedData release];
    

}

#ifndef NO_URBAN_AIRSHIP_PUSH
#pragma mark UA Init

- (void)initializeUrbanAirshipWithOptions: (NSDictionary *)options
{

    NSNumber *val = [options valueForKey:KCS_PUSH_IS_ENABLED_KEY];

    if ([val boolValue] == NO){
        // We don't want any of this code, so... we're done.
        return;
    }
    
    // Set up the UA stuff
    //Init Airship launch options
    
    NSMutableDictionary *airshipConfigOptions = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *takeOffOptions = [[[NSMutableDictionary alloc] init] autorelease];
    
    
    if ([[options valueForKey:KCS_PUSH_MODE_KEY] isEqualToString:KCS_PUSH_DEBUG]){
        [airshipConfigOptions setValue:@"NO" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:[options valueForKey:KCS_PUSH_KEY_KEY] forKey:@"DEVELOPMENT_APP_KEY"];
        [airshipConfigOptions setValue:[options valueForKey:KCS_PUSH_SECRET_KEY] forKey:@"DEVELOPMENT_APP_SECRET"];
    } else {
        [airshipConfigOptions setValue:@"YES" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:@"Your production app key" forKey:@"PRODUCTION_APP_KEY"];
        [airshipConfigOptions setValue:@"Your production app secret" forKey:@"PRODUCTION_APP_SECRET"];
    }
    
    [takeOffOptions setValue:airshipConfigOptions forKey:UAirshipTakeOffOptionsAirshipConfigKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please replace these with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    // Register for notifications through UAPush for notification type tracking
    [[UAPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeSound |
                                                         UIRemoteNotificationTypeAlert)];
    
    
    [[UAPush shared] enableAutobadge:YES];
    [[UAPush shared] resetBadge];//zero badge
    
    
}
#endif /* NO_URBAN_AIRSHIP_PUSH */

#pragma mark Initializers

- (id)initWithOptions:(NSDictionary *)kinveyOptions
{
    NSLog(@"initWithOptions:");
  
    self = [super init];
    
    if (self){
        NSMutableDictionary *optionsDictionary = [NSMutableDictionary dictionaryWithDictionary:kinveyOptions];
                                                  
        NSString *baseURL = [optionsDictionary valueForKey:KCS_BASE_URL_KEY];
        if (baseURL){
            if ([baseURL characterAtIndex:[baseURL length]-1] != '/'){
                baseURL = [baseURL stringByAppendingString:@"/"];
                [optionsDictionary setValue:baseURL forKey:KCS_BASE_URL_KEY];
            }
        }
        
        [self setOptions:optionsDictionary];
        [self setLastResponse:nil];
        [self setAppKey:[optionsDictionary valueForKey:KCS_APP_KEY_KEY]];
        [self setAppSecret:[optionsDictionary valueForKey:KCS_APP_SECRET_KEY]];
        [self setBaseURL:[optionsDictionary valueForKey:KCS_BASE_URL_KEY]];
        [self setAnalytics: [[KCSAnalytics alloc] init]];
        
        NSLog(@"Options: %@", optionsDictionary);
        

        NSString *key = [self appKey];
        NSString *secret = [self appSecret];
        NSLog(@"Kinvey Credentials: K: %@ S: %@ URL: %@", key, secret, _baseURL);

        if (key != nil && secret != nil){
            basicAuthCred = [[NSURLCredential alloc] initWithUser:key password:secret persistence:NSURLCredentialPersistenceForSession]; 
        } else {
            NSLog(@"No auth cred was provided..., authentication is not available during this session.");
            basicAuthCred = nil;
        }

        double timeout = 60.0; // Default timeout is 1 minute
        if ([optionsDictionary valueForKey:KCS_CONNECTION_TIMEOUT_KEY] != nil){
            NSNumber *t = [optionsDictionary valueForKey:KCS_CONNECTION_TIMEOUT_KEY];
            timeout = [t doubleValue];
        }
        
        [self setConnectionTimeout:timeout];
        
#ifndef NO_URBAN_AIRSHIP_PUSH
        [self initializeUrbanAirshipWithOptions:optionsDictionary];
#endif
        
    }
    
    return self;
}




- (id)initWithAppKey:(NSString *)key andSecret:(NSString *)secret usingBaseURL:(NSString *)url
{
    NSLog(@"TRACE: initWithAppKey:andSecret:usingBaseURL:");

    return [self initWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                  key, KCS_APP_KEY_KEY,
                                  secret, KCS_APP_SECRET_KEY,
                                  url, KCS_BASE_URL_KEY, nil]];
    self = [super init];
    if (self){
        // Cheat for now
        NSLog(@"Running KinveyAnalytics on Device: %@", [[self analytics] UUID]);
        
    }
    
    return self;
}


- (id)initWithAppKey:(NSString *)key andSecret:(NSString *)secret
{
    NSLog(@"TRACE: initWithAppKey:andSecret:");
    return [self initWithAppKey: key andSecret: secret usingBaseURL:nil];
}

- (id)init
{
    NSLog(@"TRACE: init:");
    return [self initWithAppKey:nil andSecret:nil usingBaseURL:nil];
}

#ifndef NO_URBAN_AIRSHIP_PUSH
#pragma mark Push
// Push helpers

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UALOG(@"Received remote notification: %@", userInfo);

    [[UAPush shared] handleNotification:userInfo applicationState:application.applicationState];
    [[UAPush shared] resetBadge]; // zero badge after push received
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    [[UAPush shared] registerDeviceToken:deviceToken];
}

- (void)setPushBadgeNumber: (int)number
{
    [[UAPush shared] setBadgeNumber:number];
}

- (void)resetPushBadge
{
    [[UAPush shared] resetBadge];//zero badge
}

- (void) exposeSettingsViewInView: (UIViewController *)parentViewController
{
    [UAPush openApnsSettings:parentViewController animated:YES];
}

#endif /* NO_URBAN_AIRSHIP_PUSH */

#pragma mark Collection Interface

// We don't want to own the collection, we just want to create the collection
// for the library client and instatiate ourselves as the KinveyClient to use
// for that collection

// Basically this is just a convienience method which I think may get
// Refactored out yet again
- (KCSCollection *)collectionFromString:(NSString *)collection
{
    return [KCSCollection collectionFromString:collection withKinveyClient:self];
}

// Basically this is just a convienience method which I think may get
// Refactored out yet again
- (KCSCollection *)collectionFromString:(NSString *)collection withClass:(Class)collectionClass
{
    return [KCSCollection collectionFromString:collection ofClass:collectionClass withKinveyClient:self];
}


#pragma mark RESTful interface

// Generic connection handler for all requests
- (void)clientActionDelegate:(id<KCSClientActionDelegate>)delegate forRequest:(NSURLRequest *)theRequest
{
    NSLog(@"clientActionDelegate:forRequest:");

    // This is not really good, we probably need to handle concurrent requests in a Queue,
    // So we need an object that can handle each request and have a Queue of requests, connections
    // and the delegates assigned to them...  This area needs help...
    [self setActionDelegate: delegate];
    
    // create the connection with the request
    // and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (theConnection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        receivedData = [[NSMutableData data] retain];

    } else {
        NSLog(@"Everythings all messed up");
        // Inform the user that the connection failed.
    }    
}

// These calls are async
// This is the actual implementation of the REST API
// GET, PUT, POST, DELETE



- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forGetRequestAtPath: (NSString *)path
{
    NSLog(@"TRACE: clientActionDelegate:forGetRequestAtPath:");
    NSURL *requestURL = [NSURL URLWithString:path];

    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:requestURL
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:[self connectionTimeout]];

    // Actually perform the connection
    [self clientActionDelegate:delegate forRequest:theRequest];
}

// The only difference between a nominal PUT and a POST is the presence of '_id'...
// Also, you can POST a map/reduce based on a post, but this is not really of concern to us in the library.

- (void)clientActionDelegate:(id<KCSClientActionDelegate>)delegate forDataRequest: (NSData *)dataRequest withMethod: (NSString *)method atPath:(NSString *)path withContentType: (NSString *)contentType;
{
    NSLog(@"TRACE: clientActionDelegate:forDataRequest:withMethod:atPath:");
    
    NSURL *requestURL = [NSURL URLWithString:path];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[self connectionTimeout]];
    
    
    // Set the METHOD for the URL Request
    [theRequest setHTTPMethod:method];
    
    // Add required fields to the header
    [theRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [theRequest addValue:[NSString stringWithFormat:@"%d", [dataRequest length]] forHTTPHeaderField:@"Content-Length"];
    
    // Add the body to the request
    [theRequest setHTTPBody:dataRequest];
    
    if ([contentType isEqualToString:KCS_JSON_TYPE]){
        NSLog(@"Content-Type: %@, Payload: %@", contentType, [dataRequest objectFromJSONData]);
    } else {
        NSLog(@"Content-Type: %@, Payload Size: %d", contentType, [dataRequest length]);
    }
    
    // Actually perform the connection
    [self clientActionDelegate:delegate forRequest:theRequest];
    
}

// TODO: This is major code duplication, but oh wells

- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPutRequest: (NSData *)putRequest atPath: (NSString *)path
{
    NSLog(@"TRACE: clientActionDelegate:forPutRequest:atPath:");
    [delegate retain];
    [self clientActionDelegate:delegate forDataRequest:putRequest withMethod:@"PUT" atPath:path withContentType:KCS_JSON_TYPE];
    [delegate release];
}

- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDataPutRequest: (NSData *)putRequest atPath: (NSString *)path
{
    NSLog(@"TRACE: clientActionDelegate:forPutRequest:atPath:");
    [delegate retain];
    [self clientActionDelegate:delegate forDataRequest:putRequest withMethod:@"PUT" atPath:path withContentType:KCS_DATA_TYPE];
    [delegate release];
}

- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPostRequest: (NSData *)postRequest atPath: (NSString *)path
{
    NSLog(@"TRACE: clientActionDelegate:forPostRequestAtPath:");
    [delegate retain];
    [self clientActionDelegate:delegate forDataRequest:postRequest withMethod:@"POST" atPath:path withContentType:KCS_JSON_TYPE];
    [delegate release];
}

- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDeleteRequestAtPath: (NSString *)path
{
    NSLog(@"TRACE: clientActionDelegate:forDeleteRequestAtPath:");
    [delegate retain];
    NSURL *requestURL = [NSURL URLWithString:path];
  
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:requestURL
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:[self connectionTimeout]];
    
    [theRequest setHTTPMethod:@"DELETE"];
    
    NSLog(@"DELETE: %@", requestURL);
    
    // Actually perform the connection
    [self clientActionDelegate:delegate forRequest:theRequest];
    [delegate release];
}



@end
