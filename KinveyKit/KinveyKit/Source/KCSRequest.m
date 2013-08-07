//
//  KCSRequest.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSRequest.h"

#import "KCSClient.h"
#import "KCSClient+KinveyKit2.h"
#import "KCSServerService.h"
#import "KCSConnectionResponse.h"
#import "KCSErrorUtilities.h"

#import "KCS_SBJson.h"
#import "NSString+KinveyAdditions.h"
#import "NSArray+KinveyAdditions.h"
#import "KCSAuthCredential.h"

#define KINVEY_KCS_API_VERSION @"3"

#define MAX_DATE_STRING_LENGTH_K 40  
NSString * getLogDate2()
{
    time_t now = time(NULL);
    struct tm *t = gmtime(&now);
    
    char timestring[MAX_DATE_STRING_LENGTH_K];
    
    NSInteger len = strftime(timestring, MAX_DATE_STRING_LENGTH_K - 1, "%a, %d %b %Y %T %Z", t);
    assert(len < MAX_DATE_STRING_LENGTH_K);
    
    return [NSString stringWithCString:timestring encoding:NSASCIIStringEncoding];
}

static const NSString* kGETMethod = @"GET";
static const NSString* kPUTMethod = @"PUT";
static const NSString* kPOSTMethod = @"POST";
static const NSString* kDELETEMethod = @"DELETE";
static const NSString* kAPPDATARoot = @"appdata";
static const NSString* kRPCRoot = @"rpc";
static const NSString* kUSERRoot = @"user";
static const NSString* kBLOBRoot = @"blob";
static const NSString* kPUSHRoot = @"push";

@implementation KCSNetworkRequest

- (instancetype) init
{
    self = [super init];
    if (self) {
        _headers = [NSMutableDictionary dictionary];
        _httpMethod = kKCSRESTMethodGET;
    }
    return self;
}


- (void)run:(void (^)(id results, NSError* error))runBlock
{
    DBAssert(_authorization != nil, @"Cannot send request, no auth provided");
    
    //TODO
    id <KCSService> service = [[KCSServerService alloc] init];
    [service performRequest:[self nsurlRequest] progressBlock:^(KCSConnectionProgress *progress) {
        //TODO
    } completionBlock:^(KCSConnectionResponse *response) {
        id results = [response jsonResponseValue];
        if (response.responseCode >= 400) {
            //TODO: domain
            NSError* error = [KCSErrorUtilities createError:results description:nil errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
            runBlock(nil, error);
        } else {
            runBlock(results, nil);
        }
    } failureBlock:^(NSError *error) {
        runBlock(nil,error);
    }];
}

- (NSString*) methodName
{
    switch (_httpMethod) {
        case kKCSRESTMethodGET:
            return (NSString*)kGETMethod;
            break;
        case kKCSRESTMethodPUT:
            return (NSString*)kPUTMethod;
            break;
        case kKCSRESTMethodPOST:
            return (NSString*)kPOSTMethod;
            break;
        case kKCSRESTMethodDELETE:
            return (NSString*)kDELETEMethod;
            break;
    }
}

- (NSString*) rootString
{
    switch (_contextRoot) {
        case kKCSContextAPPDATA:
            return (NSString*)kAPPDATARoot;
            break;
        case kKCSContextBLOB:
            return (NSString*)kBLOBRoot;
            break;
        case kKCSContextRPC:
            return (NSString*)kRPCRoot;
            break;
        case kKCSContextUSER:
            return (NSString*)kUSERRoot;
            break;
        case kKCSContextPUSH:
            return (NSString*)kPUSHRoot;
            break;
    }
}

- (NSURLRequest*) nsurlRequest
{
    KCSClient* client = [KCSClient sharedClient];
    NSArray* path = [@[[self rootString], [client kid]] arrayByAddingObjectsFromArray:[_pathComponents arrayByPercentEncoding]];
    NSString* urlStr = [path componentsJoinedByString:@"/"];
    urlStr = [[client baseURL] stringByAppendingString:urlStr];
                     
    
    NSURL* url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url]; //TODO cache & timeout
    request.HTTPMethod = [self methodName];
    
    KCS_SBJsonWriter* writer = [[KCS_SBJsonWriter alloc] init];

    if (_body) {
        NSData* bodyData = [writer dataWithObject:_body];        
        DBAssert(bodyData != nil, @"should be able to parse body");
        [request setHTTPBody:bodyData];
    }
    
    NSString* auth = [_authorization authString];
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithCapacity:15];
    //TODO: other headers
    if (auth) {
        headers[@"Authorization"] = auth;
    }
    headers[@"User-Agent"] = [client userAgent];
    headers[@"X-Kinvey-Device-Information"] = [client.analytics headerString];
    headers[@"X-Kinvey-API-Version"] = KINVEY_KCS_API_VERSION;
    headers[@"Date"] = getLogDate2();
    headers[@"X-Kinvey-ResponseWrapper"] = @"true";
    headers[@"Content-Type"] = @"application/json";
    [headers addEntriesFromDictionary:_headers];
    [request setAllHTTPHeaderFields:headers];
    
    [request setHTTPShouldUsePipelining:_httpMethod != kKCSRESTMethodPOST];
    //TODO followsRedirects
    return request;
}

- (void)setAuthorization:(id<KCSCredentials>)authorization
{
    NSParameterAssert(authorization);    
    _authorization = authorization;
}

@end

@implementation KCSCacheRequest

@end
