//
//  KinveyClient.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSClient.h"

#define KCS_JSON_TYPE @"application/json"
#define KCS_DATA_TYPE @"application/octet-stream"

// Anonymous category on KCSClient, used to allow us to redeclare readonly properties
// readwrite.  This keeps KVO notation, while allowing private mutability.
@interface KCSClient ()
    // Redeclare private iVars
    @property (readwrite) double connectionTimeout;
@end

@implementation KCSClient

@synthesize receivedData;
@synthesize lastResponse=_lastResponse;
@synthesize appKey;
@synthesize appSecret;
@synthesize baseURI;
@synthesize basicAuthCred;
@synthesize actionDelegate;
@synthesize connectionTimeout;
@synthesize options;

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
    [receivedData release];
    
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
    [[self lastResponse] release]; // Initialized to nil, so this does nothing if we don't have a last response
    [self setLastResponse:response];
    
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
    [receivedData release];
    

}



- (id)initWithAppKey:(NSString *)key andSecret:(NSString *)secret usingBaseURI:(NSString *)uri
{
    NSLog(@"TRACE: initWithAppKey:andSecret:usingBaseURI:");
    self = [super init];
    if (self){
        [self setLastResponse:nil];
        [self setAppKey: key];
        [self setAppSecret: secret];
        [self setBaseURI: uri];
        if (key != nil && secret != nil){
            basicAuthCred = [[NSURLCredential alloc] initWithUser:key password:secret persistence:NSURLCredentialPersistenceForSession]; 
        } else {
            NSLog(@"No auth cred was provided..., authentication is not available during this session.");
            basicAuthCred = nil;
        }
        
        [self setConnectionTimeout:60.0];
        
        // Make sure that our options dictionary is valid
        if (options == Nil){
            options = [[NSDictionary alloc] initWithObjectsAndKeys:@"appKey", key, @"appSecret", secret, @"baseURI", uri, nil];
        }
    }
    
    return self;
}


- (id)initWithAppKey:(NSString *)key andSecret:(NSString *)secret
{
    NSLog(@"TRACE: initWithAppKey:andSecret:");
    return [self initWithAppKey: key andSecret: secret usingBaseURI:nil];
}

- (id)init
{
    NSLog(@"TRACE: init:");
    return [self initWithAppKey:nil andSecret:nil usingBaseURI:nil];
}

- (id)initWithOptions:(NSDictionary *)optionsDictionary
{
    NSLog(@"initWithOptions:");
    
    NSString *portString;
    if ([optionsDictionary valueForKey:@"kinveyPort"] != nil){
        portString = [@":" stringByAppendingString: [options valueForKey:@"kinveyPort"]];
    } else {
        portString = @"";
    }

    // Extract the relevant info and build the baseURI string. 
    NSString *uri = [NSString stringWithFormat:@"https://%@.kinvey.com%@/appdata/%@",
                     [options valueForKey:@"service"],
                     portString,
                     [options valueForKey:@"appKey"]];
    
    [options setValue:uri forKey:@"baseURI"];
    
    self = [self initWithAppKey:[options valueForKey:@"appKey"] andSecret: [options valueForKey:@"appSecret"] usingBaseURI:uri];
    
    if (self){
        [self setOptions:optionsDictionary];
    }
    
    return self;
}


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
    NSURL *requestURL = [NSURL URLWithString:[baseURI stringByAppendingString:path]];
    
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
    NSURL *requestURL = [NSURL URLWithString:[baseURI stringByAppendingString:path]];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[self connectionTimeout]];
    
    
    // Set the METHOD for the URL Request
    [theRequest setHTTPMethod:method];
    
    // Add required fields to the header
    [theRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    // Add the body to the request
    [theRequest setHTTPBody:dataRequest];
    
    
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
    NSURL *requestURL = [NSURL URLWithString:[baseURI stringByAppendingString:path]];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:requestURL
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:[self connectionTimeout]];
    
    // Actually perform the connection
    [self clientActionDelegate:delegate forRequest:theRequest];
    [delegate release];
}



@end
