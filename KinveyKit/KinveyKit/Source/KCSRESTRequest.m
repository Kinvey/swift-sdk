//
//  KCSRESTRequest.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSRESTRequest.h"
#import "KCSConnectionPool.h"
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KCSLogManager.h"
#import "KCSAuthCredential.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSReachability.h"
#import "KinveyAnalytics.h"

// *cough* hack *cough*
#define MAX_DATE_STRING_LENGTH_K 40 
#define MAX_NUMBER_OF_RETRIES_K 10
// This is in Seconds!
#define KCS_RETRY_DELAY 0.05

// KINVEY KCS API VERSION
#define KINVEY_KCS_API_VERSION_HEADER @"X-Kinvey-API-Version"

// For when api 1 is complete
// #define KINVEY_KCS_API_VERSION @"1"
#define KINVEY_KCS_API_VERSION @"0"


void clogResource(NSString *resource, NSInteger requestMethod);
void clogResource(NSString *resource, NSInteger requestMethod)
{
    KCSLogDebug(@"cLogResource: (%@[%p], %d)", resource, (void *)resource, requestMethod);
}


NSString *getLogDate(void); // Make compiler happy...

NSString *
getLogDate(void)
{
    time_t now = time(NULL);
    struct tm *t = gmtime(&now);
    
    char timestring[MAX_DATE_STRING_LENGTH_K];
    
    int len = strftime(timestring, MAX_DATE_STRING_LENGTH_K - 1, "%a, %d %b %Y %T %Z", t);
    assert(len < MAX_DATE_STRING_LENGTH_K);
    
    return [NSString stringWithCString:timestring encoding:NSASCIIStringEncoding];
}


@interface KCSRESTRequest()
@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic) BOOL isMockRequest;
@property (nonatomic, retain) Class mockConnection;
@property (nonatomic) NSInteger retriesAttempted;
- (id)initWithResource:(NSString *)resource usingMethod: (NSInteger)requestMethod;
@end

@implementation KCSRESTRequest

@synthesize resourceLocation=_resourceLocation;
@synthesize completionAction=_completionAction;
@synthesize failureAction=_failureAction;
@synthesize progressAction=_progressAction;
@synthesize headers=_headers;
@synthesize method=_method;
@synthesize isSyncRequest=_isSyncRequest;
@synthesize isMockRequest=_isMockRequest;
@synthesize mockConnection=_mockConnection;
@synthesize request=_request;
@synthesize followRedirects=_followRedirects;
@synthesize retriesAttempted = _retriesAttempted;

- (id)initWithResource:(NSString *)resource usingMethod: (NSInteger)requestMethod
{
    self = [super init];
    if (self){
        self.resourceLocation = resource; // I own this!
        _method = requestMethod;
        _completionAction = NULL;
        _progressAction = NULL;
        _failureAction = NULL;
        _isSyncRequest = NO;
        _isMockRequest = NO;
        _followRedirects = YES;
        _retriesAttempted = 0;
        _headers = [[NSMutableDictionary dictionary] retain];

        // Prepare to generate the request...
        KCSClient *kinveyClient = [KCSClient sharedClient];

        // NB: Not retained as it is only used in the building of _request
        NSURL *url = [NSURL URLWithString:resource];
        
        KCSLogNetwork(@"Requesting resource: %@", resource);
        _request = [[NSMutableURLRequest requestWithURL:url cachePolicy:kinveyClient.cachePolicy timeoutInterval:kinveyClient.connectionTimeout] retain];
    }
    return self;
}

- (void)dealloc
{
    [_resourceLocation release]; 
    [_headers release];

    _resourceLocation = nil;
    _headers = nil;
    
    [_request release];
    self.completionAction = NULL;
    self.progressAction = NULL;
    self.failureAction = NULL;
    
    [super dealloc];
}

- (void)logResource: (NSString *)resource usingMethod: (NSInteger)requestMethod
{
    KCSLogNetwork(@"logResource: (%@[%p], %d)", resource, (void *)resource, requestMethod);
}

+ (KCSRESTRequest *)requestForResource: (NSString *)resource usingMethod: (NSInteger)requestMethod
{
    return [[[KCSRESTRequest alloc] initWithResource:resource usingMethod:requestMethod] autorelease];
}

- (id)syncRequest
{
    self.isSyncRequest = YES;
    return self;
}

- (id)mockRequestWithMockClass:(Class)connection
{
    self.isMockRequest = YES;
    self.mockConnection = connection;
    return self;
}

- (id)addHeaders: (NSDictionary *)theHeaders
{
    NSArray *keys = [theHeaders allKeys];
    
    for (NSString *key in keys) {
        [self.headers setObject:[theHeaders objectForKey:key] forKey:key];
    }
    
    return self;
}

- (id)addBody:(NSData *)theBody
{
    [self.request setHTTPBody:theBody];
    [self.request setValue:[NSString stringWithFormat:@"%d", [theBody length]] forHTTPHeaderField:@"Content-Length"];
    return self;
}

- (id)withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failure progressAction: (KCSConnectionProgressBlock)progress
{
    // The analyzer complains that there is a memory leak, it's cause I'm copying these values (alloc'ing them) but never freeing them... 
//    self.completionAction = [complete copy];
//    self.progressAction = [progress copy];
//    self.failureAction = [failure copy];
    self.completionAction = complete;
    self.progressAction = progress;
    self.failureAction = failure;
    
    return self;
    
}

// Modify known headers
- (void)setContentType: (NSString *)contentType
{
    [self.headers setObject:contentType forKey:@"Content-Type"];
}

- (void)setContentLength: (NSInteger)contentLength
{
    [self.headers setObject:[NSNumber numberWithInt:contentLength] forKey:@"Content-Length"];    
}

// Prototype is to make compiler happy
- (NSString *)getHTTPMethodForConstant:(NSInteger)constant
{
    switch (constant) {
        case kGetRESTMethod:
            return @"GET";
            break;
        case kPutRESTMethod:
            return @"PUT";
            break;
        case kPostRESTMethod:
            return @"POST";
            break;
        case kDeleteRESTMethod:
            return @"DELETE";
            break;
            
        default:
            return @"";
            break;
    }
}


- (void)start
{
    KCSConnection *connection;
    KCSClient *kinveyClient = [KCSClient sharedClient];
   
    // Check for reachability here, but how do we allow for mock testing?
    if (![kinveyClient.kinveyReachability isReachable]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Kinvey not reachable"
                                                                           withFailureReason:@"Reachability determined that Kinvey was not reachable."
                                                                      withRecoverySuggestion:@"Check to make sure device is not in Airplane mode and has a signal or try again later"
                                                                         withRecoveryOptions:nil];
        NSError *error = [NSError errorWithDomain:KCSNetworkErrorDomain
                                             code:KCSKinveyUnreachableError
                                         userInfo:userInfo];
        self.failureAction(error);
        // No connection, no release
        return;
    }

    
    if (self.isSyncRequest){
        connection = [[KCSConnectionPool syncConnection] retain];
    } else if (self.isMockRequest) {
        connection = [[KCSConnectionPool connectionWithConnectionType:self.mockConnection] retain];
    } else {
        connection = [[KCSConnectionPool asyncConnection] retain];
    }
    
    [self.request  setHTTPMethod: [self getHTTPMethodForConstant: self.method]];
    
    for (NSString *key in [self.headers allKeys]) {
        [self.request setValue:[self.headers objectForKey:key] forHTTPHeaderField:key];
    }
    
    // Add the Kinvey User-Agent
    [self.request setValue:[kinveyClient userAgent] forHTTPHeaderField:@"User-Agent"];
    
    // Add the Analytics header
    [self.request setValue:[kinveyClient.analytics headerString] forHTTPHeaderField:kinveyClient.analytics.analyticsHeaderName];
    
    // Add the API version
    [self.request setValue:KINVEY_KCS_API_VERSION forHTTPHeaderField:KINVEY_KCS_API_VERSION_HEADER];

    // Add the Date as a header
    [self.request setValue:getLogDate() forHTTPHeaderField:@"Date"];

    // Let the server know that we support GZip.
    [self.request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

    KCSAuthCredential *cred = [KCSAuthCredential credentialForURL:self.resourceLocation usingMethod:self.method];
    if (cred.requiresAuthentication){
        NSString *authString = [cred HTTPBasicAuthString];
        // If authString is nil and we needed it (requiresAuthentication is true),
        // then there is no current user, so we need to retry this "later", say 500 msec
        if (authString == nil){
            // We're only going to try this so many times before we just give up
            if (self.retriesAttempted >= MAX_NUMBER_OF_RETRIES_K){
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Request Timeout"
                                                                                   withFailureReason:@"Authentication service failed to return valid credentials after multiple attempts." 
                                                                              withRecoverySuggestion:@"Check to see if the network is active."
                                                                                 withRecoveryOptions:nil];
                
                self.failureAction([NSError errorWithDomain:KCSUserErrorDomain
                                                          code:KCSAuthenticationRetryError
                                                      userInfo:userInfo]);
            } else {
                self.retriesAttempted++;
                [self performSelector:@selector(start) withObject:nil afterDelay:KCS_RETRY_DELAY];
                // This iteration is done.
            }
            [connection release];
            return;
        }
        [self.request setValue:authString forHTTPHeaderField:@"Authorization"];
    }
    

    
    if (!self.followRedirects){
        connection.followRedirects = NO;
    }
    
    [connection performRequest:self.request progressBlock:self.progressAction completionBlock:self.completionAction failureBlock:self.failureAction usingCredentials:nil];    
     
    [connection release];
}

@end
