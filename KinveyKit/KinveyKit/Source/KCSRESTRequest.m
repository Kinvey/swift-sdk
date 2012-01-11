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

// *cough* hack *cough*
#define MAX_DATE_STRING_LENGTH_K 40 

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

//- (id)init
//{
//    self = [super init];
//    
//    if (self){
//        _headers = [[NSMutableDictionary dictionary] retain];
//    }
//    return self;
//}

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
        _headers = [[NSMutableDictionary dictionary] retain];

        // Prepare to generate the request...
        KCSClient *kinveyClient = [KCSClient sharedClient];
//        NSString *urlString = [NSString stringWithFormat:@"%@%@:%@@%@", kinveyClient.protocol, kinveyClient.authCredentials.user, kinveyClient.authCredentials.password, self.resourceLocation];
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
//    KCSRESTRequest *request = [KCSRESTRequest alloc];
//    request.resourceLocation = resource;
//    request.method = requestMethod;
//    
//    [request logResource:resource usingMethod:requestMethod];
//    clogResource(resource, requestMethod);
//
//    [request autorelease];
//    return request;
//
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
    // The analyzer complains that there is a memory leak 
    self.completionAction = [complete copy];
    self.progressAction = [progress copy];
    self.failureAction = [failure copy];
    
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
    
    if (self.isSyncRequest){
        connection = [[KCSConnectionPool syncConnection] retain];
    } else if (self.isMockRequest) {
        connection = [[KCSConnectionPool connectionWithConnectionType:self.mockConnection] retain];
    } else {
        connection = [[KCSConnectionPool asyncConnection] retain];
    }
    
    [self.request  setHTTPMethod: [self getHTTPMethodForConstant: self.method]];
    
    for (NSString *key in [self.headers allKeys]) {
        [self.request addValue:[self.headers objectForKey:key] forHTTPHeaderField:key];
    }
    
    // We need to do basic filtering on the request URL and do some things for "Kinvey" requests
    
    // Add the Kinvey User-Agent
    [self.request addValue:[kinveyClient userAgent] forHTTPHeaderField:@"User-Agent"];

    // Add the Date as a header
    [self.request addValue:getLogDate() forHTTPHeaderField:@"Date"];

    // Let the server know that we support GZip.
    [self.request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];  
    
    // If we have the proper credentials then kinveyClient.userIsAuthenticated returns true, so just use the stored credentials
    // If it's not true, then we could be in the acutal user request, if that's the case (aka, resourceLocation is the userBaseURL)
    // then just allow the requst, it's already authenticated...
    // TODO: this needs to check each URL for the user API, since future maybe more than just the baseURL.
    if (!kinveyClient.userIsAuthenticated && ![self.resourceLocation isEqualToString:kinveyClient.userBaseURL]){
        // User isn't authenticated, we need to perform default auth here and return.  Auth will handle completing this request.
//        KCSLogDebug(@"Username: %@ Password: %@", kinveyClient.authCredentials.user, kinveyClient.authCredentials.password);
        [kinveyClient.currentUser initializeCurrentUserWithRequest:self];
        // Make sure to release the connection here, as we're breaking.
        [connection release];
        return;
    }
    
    if (!self.followRedirects){
        connection.followRedirects = NO;
    }
    
    [connection performRequest:self.request progressBlock:self.progressAction completionBlock:self.completionAction failureBlock:self.failureAction usingCredentials:[kinveyClient authCredentials]];
     
    [connection release];
}

@end
