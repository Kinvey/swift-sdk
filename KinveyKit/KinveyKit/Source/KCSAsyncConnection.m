//
//  KCSAsyncConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSAsyncConnection.h"
#import "KCSConnectionResponse.h"
#import "KCSConnectionProgress.h"

@interface KCSAsyncConnection()


@property (copy) KCSConnectionCompletionBlock completionBlock;
@property (copy) KCSConnectionFailureBlock    failureBlock;
@property (copy) KCSConnectionProgressBlock   progressBlock;
@property (retain, readwrite) NSMutableData *activeDownload;
@property (retain) NSURLConnection *connection;
@property (nonatomic, readwrite) NSInteger contentLength;
@property NSInteger lastPercentage;

@end

@implementation KCSAsyncConnection

@synthesize activeDownload=_activeDownload;
@synthesize lastResponse=_lastResponse;
@synthesize request = _request;
@synthesize basicAuthCred=_basicAuthCred;

@synthesize completionBlock=_completionBlock;
@synthesize failureBlock=_failureBlock;
@synthesize progressBlock=_progressBlock;
@synthesize connection=_connection;

@synthesize percentComplete=_percentComplete;
@synthesize percentNotificationThreshold=_percentNotificationThreshold;

@synthesize contentLength=_contentLength;
@synthesize connectionTimeout=_connectionTimeout;

@synthesize lastPercentage=_lastPercentage;

/* NOTES:
 
 Lifecycle:
 KCSConnections are designed to be reusable and to live in a connection pool, this means
 that the normal lifecycle of alloc -> release isn't followed, but there will be multiple
 uses for each connection (assumed), so the following is the expected life cycle
 1. Alloc/init
 ...
 2. [self performRequest]
 3. NSURLConnection Delegate Sequence
 4. ConnectionDidFinishLoading/ConnectionDidFail
 5. cleanUp
 ...
 6. dealloc
 
 Where 2 through 5 are called repeatedly.
 
 Step 5 needs to pay close attention to any copy parameters, otherwise calling the setter for the member and
 assinging to nil should free the memory.
 
 */


#pragma mark -
#pragma mark Constructors

//- (id)initWithCredentials:(NSURLCredential *)credentials
//{
//    self = [super self];
//    if (self){
//        _activeDownload = nil;
//        _lastResponse = nil;
//        _request = nil;
//        _connection = nil;
//        _percentNotificationThreshold = 1; // Default to 1%
//        _lastPercentage = 0; // Start @ 0%
//        // Don't cache the Auth, just in case we switch it up later...
//        _basicAuthCred = [credentials retain];  // We own this now...
//    }
//    return self;
//}
//
//- (id)initWithUsername:(NSString *)username password:(NSString *)password
//{
//    return [self initWithCredentials:[NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone]];
//}

- (id)initWithConnection:(NSURLConnection *)theConnection
{
    self = [self init]; // Note that in the test environment we don't need credentials
    if (self){
        self.connection = theConnection; // Otherwise this value is nil...
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self){
        _activeDownload = nil;
        _lastResponse = nil;
        _request = nil;
        _connection = nil;
        _percentNotificationThreshold = 1; // Default to 1%
        _lastPercentage = 0; // Start @ 0%
        self.followRedirects = YES;
        // Don't cache the Auth, just in case we switch it up later...
        _basicAuthCred = nil;
    }
    return self;
}

#pragma mark -
#pragma mark Setters/Getters

// Getter for percentComplete
- (double)percentComplete
{
    if (self.contentLength <= 0){
        return 0;
    } else {
        return (([self.activeDownload length] * 1.0) / self.contentLength) * 100;
    }
    
}

#pragma mark -
#pragma mark Primary Interface

- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials
{
    self.request = theRequest;
    self.progressBlock = onProgress;
    self.failureBlock = onFailure;
    self.completionBlock = onCompletion;
    self.basicAuthCred = credentials;
    
    // If our connection has been cleaned up, then we need to make sure that we get it back before using it.
    if (self.connection == nil){
        self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self]; // Retained due to accessor
    }
    
    if (self.connection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        self.activeDownload = [[NSMutableData data] retain];
    } else {
        NSLog(@"KCSConnection: Connection unabled to be created.");
        // TODO, make error codes, provide some userInfo love, probably make a Kinvey Error class and use that for these values
        NSError *error = [NSError errorWithDomain:@"KinveyError" code:1 userInfo:nil];
        self.failureBlock(error);
    }
}

- (void)cleanUp
{
    // Cause all members to release their current object and reset to the nil state.
    self.request = nil;
    self.basicAuthCred = nil;
    self.connection = nil;
    self.activeDownload = nil;
    self.lastResponse = nil;
    self.lastPercentage = 0; // Reset

    [_request release];
    [_progressBlock release];
    [_completionBlock release];
    [_failureBlock release];
    _progressBlock = NULL;
    _completionBlock = NULL;
    _failureBlock = NULL;

}

#pragma mark -
#pragma mark Download support (NSURLConnectionDelegate)

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
//    NSLog(@"ProtectionSpace %@ requesting method %@ (Using protocol %@ with host %@)", protectionSpace, protectionSpace.authenticationMethod, protectionSpace.protocol, protectionSpace.host);
    return YES;
//    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]){
//        return YES;
//    } else {
//        NSLog(@"Unsupported Authentication Metchod called: %@ (%@)", protectionSpace.authenticationMethod, protectionSpace);
//        return NO;
//    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"TRACE: connection:didCancelAuthenticationChallenge:");
    NSLog(@"*** This is very unexpected and a serious error, please contact support@kinvey.com (%@)", challenge);
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    // Right now this might need to be implemented to support Ivan's Stuff
    return NO;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"Connection WILL authenticate with: (%@, %@)", self.basicAuthCred.user, self.basicAuthCred.password);
    [[challenge sender] useCredential:self.basicAuthCred forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"Connection DID authenticate with: (%@, %@)", self.basicAuthCred.user, self.basicAuthCred.password);
    [[challenge sender] useCredential:self.basicAuthCred forAuthenticationChallenge:challenge];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.activeDownload appendData:data];
    

    double downloadPercent = floor(self.percentComplete);
    // TODO: Need to check percent complete threshold...
    if (self.progressBlock != NULL &&
        ((self.lastPercentage + self.percentNotificationThreshold) <= downloadPercent)){
        // Probably want to handle this differently, since now the caller needs to know what's going
        // on, but I think that at a minimum, we need progress + data.
        self.lastPercentage = downloadPercent; // Update to the current value
        self.progressBlock([[[KCSConnectionProgress alloc] init] autorelease]);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);

    // Clear the activeDownload property to allow later attempts
    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.connection = nil;
 
    // Notify client that the operation failed!
    self.failureBlock(error);
    
    [self cleanUp];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Need to set content lenght field and lastResponse fields...
    self.lastResponse = response; // This properly updates our last response

    // All connections are HTTP connections, so a valid response is HTTP
    NSDictionary *header = [(NSHTTPURLResponse *)response allHeaderFields];
    NSString *contentLengthString = [header valueForKey:@"Content-Length"];
    
    // This means we have a valid content-length
    if (contentLengthString != nil){
        self.contentLength = [contentLengthString integerValue];
    } else {
        self.contentLength = -1;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSInteger statusCode = [(NSHTTPURLResponse *)self.lastResponse statusCode];
    NSDictionary *headers = [(NSHTTPURLResponse *)self.lastResponse allHeaderFields];
    self.completionBlock([KCSConnectionResponse connectionResponseWithCode:statusCode responseData:self.activeDownload headerData:headers userData:nil]);
    
    self.activeDownload = nil;
    self.connection = nil;
    
    [self cleanUp];
}

// Don't honor the redirect, just grab the location and move on...
-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    NSURLRequest *newRequest = request;
    if (redirectResponse && !self.followRedirects) {
        newRequest = nil;
    }
    return newRequest;
}



@end
