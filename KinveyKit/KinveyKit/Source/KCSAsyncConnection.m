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
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "KCSLogManager.h"


@interface KCSAsyncConnection()


@property (copy) KCSConnectionCompletionBlock completionBlock;
@property (copy) KCSConnectionFailureBlock    failureBlock;
@property (copy) KCSConnectionProgressBlock   progressBlock;
@property (nonatomic, retain) NSMutableData *downloadedData;
@property (retain) NSURLConnection *connection;
@property (nonatomic, readwrite) NSInteger contentLength;
@property NSInteger lastPercentage;

@end

@implementation KCSAsyncConnection

@synthesize downloadedData = _downloadedData;

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
        _downloadedData = nil;
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
        return (([self.downloadedData length] * 1.0) / self.contentLength) * 100;
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

    KCSLogNetwork(@"Request URL:%@", self.request.URL);
    KCSLogNetwork(@"Request Method:%@", self.request.HTTPMethod);
    KCSLogNetwork(@"Request Headers:%@", self.request.allHTTPHeaderFields);

    
    // If our connection has been cleaned up, then we need to make sure that we get it back before using it.
    if (self.connection == nil){
        self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self]; // Retained due to accessor
    } else {
        // This method only starts the connection if it's not been started, if we somehow end up here
        // without a started connection... well... we need to start it.
        [self.connection start];
    }
    
    if (self.connection) {
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        // This is released by the cleanup method called when the connection completes or fails
        self.downloadedData = [NSMutableData data];
    } else {
        KCSLogNetwork(@"KCSConnection: Connection unabled to be created.");
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to create network connection.s"
                                                                           withFailureReason:@"connectionWithRequest:delegate: returned nil connection."
                                                                      withRecoverySuggestion:@"Retry request."
                                                                         withRecoveryOptions:nil];

        NSError *error = [NSError errorWithDomain:KCSNetworkErrorDomain
                                             code:KCSUnderlyingNetworkConnectionCreationFailureError
                                         userInfo:userInfo];
        self.failureBlock(error);
    }
}

- (void)cleanUp
{
    // Cause all members to release their current object and reset to the nil state.
    [_request release];
    [_basicAuthCred release];
    [_connection release];
    [_lastResponse release];
    [_downloadedData release];
    [_progressBlock release];
    [_completionBlock release];
    [_failureBlock release];

    _request = nil;
    _basicAuthCred = nil;
    _connection = nil;
    _lastResponse = nil;
    _downloadedData = nil;
    _progressBlock = NULL;
    _completionBlock = NULL;
    _failureBlock = NULL;

    self.lastPercentage = 0; // Reset
}

#pragma mark -
#pragma mark Download support (NSURLConnectionDelegate)

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    KCSLogTrace(@"connection:didCancelAuthenticationChallenge:");
    KCSLogError(@"*** This is very unexpected and a serious error, please contact support@kinvey.com (%@)", challenge);
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    // Right now this might need to be implemented to support Ivan's Stuff
    return NO;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] useCredential:self.basicAuthCred forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] useCredential:self.basicAuthCred forAuthenticationChallenge:challenge];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Update downloaded data with new data
    [self.downloadedData appendData:data];
    

    // Update download percent and call the progress block
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
    KCSLogError(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);

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
    KCSLogNetwork(@"Response completed with code %d and response headers: %@", statusCode, headers);
    KCSLogDebug(@"Kinvey Request ID: %@", [headers objectForKey:@"X-Kinvey-Request-Id"]);
    self.completionBlock([KCSConnectionResponse connectionResponseWithCode:statusCode responseData:self.downloadedData headerData:headers userData:nil]);    
    
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
