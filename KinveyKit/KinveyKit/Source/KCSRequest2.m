//
//  KCSRequest2.m
//  KinveyKit
//
//  Created by Michael Katz on 8/12/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KCSRequest2.h"
#import "KinveyCoreInternal.h"

#import "KCSNSURLRequestOperation.h"
#import "KCSMockRequestOperation.h"
#import "KCSNSURLSessionOperation.h"

#define kHeaderAuthorization   @"Authorization"
#define kHeaderDate            @"Date"
#define kHeaderUserAgent       @"User-Agent"
#define kHeaderApiVersion      @"X-Kinvey-Api-Version"
#define kHeaderClientMethod    @"X-Kinvey-Client-Method"
#define kHeaderDeviceInfo      @"X-Kinvey-Device-Information"
#define kHeaderResponseWrapper @"X-Kinvey-ResponseWrapper"
#define kHeaderBypassBL        @"x-kinvey-skip-business-logic"

#define kHeaderValueJson @"application/json"

#define kErrorKeyMethod @"KinveyKit.HTTPMethod"

#define kMaxTries 5

KCS_CONST_IMPL KCSRequestOptionClientMethod = kHeaderClientMethod;
KCS_CONST_IMPL KCSRequestOptionUseMock      = @"UseMock";
KCS_CONST_IMPL KCSRESTRouteAppdata          = @"appdata";
KCS_CONST_IMPL KCSRESTRouteUser             = @"user";
KCS_CONST_IMPL KCSRESTRouteBlob             = @"blob";
KCS_CONST_IMPL KCSRESTRouteRPC              = @"rpc";
KCS_CONST_IMPL KCSRESTRoutePush             = @"push";
KCS_CONST_IMPL KCSRestRouteTestReflection   = @"!reflection";

KCS_CONST_IMPL KCSRESTMethodDELETE = @"DELETE";
KCS_CONST_IMPL KCSRESTMethodGET    = @"GET";
KCS_CONST_IMPL KCSRESTMethodPATCH  = @"PATCH";
KCS_CONST_IMPL KCSRESTMethodPOST   = @"POST";
KCS_CONST_IMPL KCSRESTMethodPUT    = @"PUT";

#define KCS_VERSION @"3"


#define MAX_DATE_STRING_LENGTH_K 40
KK2(make just 1)
NSString * getLogDate3()
{
    time_t now = time(NULL);
    struct tm *t = gmtime(&now);
    
    char timestring[MAX_DATE_STRING_LENGTH_K];
    
    NSInteger len = strftime(timestring, MAX_DATE_STRING_LENGTH_K - 1, "%a, %d %b %Y %T %Z", t);
    assert(len < MAX_DATE_STRING_LENGTH_K);
    
    return [NSString stringWithCString:timestring encoding:NSASCIIStringEncoding];
}


@interface KCSRequest2 ()
@property (nonatomic) BOOL useMock;
@property (nonatomic, copy) KCSRequestCompletionBlock completionBlock;
@property (nonatomic, copy) NSString* contentType;
@property (nonatomic, retain) NSOperationQueue* currentQueue;
@property (nonatomic, weak) id<KCSCredentials> credentials;
@property (nonatomic, retain) NSString* route;
@property (nonatomic, copy) NSDictionary* options;
@end

@implementation KCSRequest2

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 4;
    [queue setName:@"com.kinvey.KinveyKit.RequestQueue"];
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion route:(NSString*)route options:(NSDictionary*)options credentials:(id)credentials;
{
    KCSRequest2* request = [[KCSRequest2 alloc] init];
    request.useMock = [options[KCSRequestOptionUseMock] boolValue];
    request.completionBlock = completion;
    request.credentials = credentials;
    request.route = route;
    request.options = options;
    return request;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _contentType = kHeaderValueJson;
        _method = KCSRESTMethodGET;
    }
    return self;
}


# pragma mark -
- (NSString*)finalURL
{
    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
    NSString* baseURL = [config baseURL];
    NSString* kid = config.appKey;

    if (_useMock && kid == nil) {
        kid = @"mock";
        baseURL = baseURL ? baseURL : @"http://localhost:2110/";
    }
    
    NSArray* path = [@[self.route, kid] arrayByAddingObjectsFromArray:[_path arrayByPercentEncoding]];
    NSString* urlStr = [path componentsJoinedByString:@"/"];
    if (self.queryString) {
        urlStr = [urlStr stringByAppendingString:self.queryString];
    }
    NSString* endpoint = [baseURL stringByAppendingString:urlStr];

    return endpoint;
}

- (NSMutableURLRequest*)urlRequest
{
    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
    NSString* endpoint = [self finalURL];
    
    NSURL* url = [NSURL URLWithString:endpoint];
    DBAssert(url, @"Should have a valid url");

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:[config.options[KCS_URL_CACHE_POLICY] unsignedIntegerValue]
                                                       timeoutInterval:[config.options[KCS_CONNECTION_TIMEOUT] doubleValue]];
    request.HTTPMethod = self.method;
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    headers[kHeaderAuthorization] = [self.credentials authString];
    headers[kHeaderApiVersion] = KCS_VERSION;
    headers[kHeaderUserAgent] = [NSString stringWithFormat:@"ios-kinvey-http/%@ kcs/%@", __KINVEYKIT_VERSION__, MINIMUM_KCS_VERSION_SUPPORTED];
    headers[kHeaderDeviceInfo] = [KCSPlatformUtils platformString];
    headers[kHeaderResponseWrapper] = @"true";
    setIfValNotNil(headers[kHeaderClientMethod], self.options[KCSRequestOptionClientMethod]);

    [headers addEntriesFromDictionary:self.headers];
    
    headers[kHeaderDate] = getLogDate3(); //always update date
    [request setAllHTTPHeaderFields:headers];
    
    [request setHTTPShouldUsePipelining:YES];

    if (self.method == KCSRESTMethodPOST || self.method == KCSRESTMethodPUT) {
        [request setHTTPShouldUsePipelining:NO];
        //set the body
        if (!_body) {
            _body = @{};
        }
        KCS_SBJsonWriter* writer = [[KCS_SBJsonWriter alloc] init];
        NSData* bodyData = [writer dataWithObject:_body];
        DBAssert(bodyData != nil, @"should be able to parse body");
        [request setHTTPBody:bodyData];
        [request addValue:_contentType forHTTPHeaderField:kHeaderContentType];
    } else if (self.method == KCSRESTMethodDELETE) {
        // [request setHTTPBody:bodyData]; no need for body b/c of no content type
    }

    return request;
}

- (id<KCSNetworkOperation>) start
{
    NSAssert(_route, @"should have route");
    if (self.credentials == nil) {
        NSError* error = [NSError errorWithDomain:KCSNetworkErrorDomain code:KCSDeniedError userInfo:@{NSLocalizedDescriptionKey : @"No Authorization Found", NSLocalizedFailureReasonErrorKey : @"There is no active user/client and this request requires credentials.", NSURLErrorFailingURLStringErrorKey : [self finalURL]}];
        self.completionBlock(nil, error);
        return nil;
    }
    NSAssert(self.credentials, @"should have credentials");
    DBAssert(self.options[KCSRequestOptionClientMethod], @"DB should set client method");
    
    _currentQueue = [NSOperationQueue currentQueue];
    NSMutableURLRequest* request = [self urlRequest];
    
    NSOperation<KCSNetworkOperation>* op = nil;
    if (_useMock == YES) {
        op = [[KCSMockRequestOperation alloc] initWithRequest:request];
    } else {
        
        if ([KCSPlatformUtils supportsNSURLSession]) {
            op = [[KCSNSURLSessionOperation alloc] initWithRequest:request];
        } else {
            op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
        }
    }

    op.clientRequestId = [NSString UUID];
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@ [KinveyKit id: '%@']", request.HTTPMethod, request.URL, op.clientRequestId);

    
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        [self requestCallback:op request:request];
    };
    [queue addOperation:op];
    return op;
}

- (void) requestCallback:(NSOperation<KCSNetworkOperation>*)op request:(NSURLRequest*)request
{
    if ([[KCSClient sharedClient].options[KCS_CONFIG_RETRY_DISABLED] boolValue] == YES) {
        [self callCallback:op request:request];
    } else {
        if (opIsRetryableNetworkError(op)) {
            KCSLogNotice(KCS_LOG_CONTEXT_NETWORK, @"Retrying request (%@). Network error: %ld.", op.clientRequestId, (long)op.error.code);
            [self retryOp:op request:request];
        } else if (opIsRetryableKCSError(op)) {
            KCSLogNotice(KCS_LOG_CONTEXT_NETWORK, @"Retrying request (%@). Kinvey server error: %@", op.clientRequestId, [op.response jsonObject]);
            [self retryOp:op request:request];
        } else {
            //status OK or is a non-retryable error
            [self callCallback:op request:request];
        }
    }
}

BOOL opIsRetryableNetworkError(NSOperation<KCSNetworkOperation>* op)
{
    BOOL isError = NO;
    if (op.error) {
        if ([[op.error domain] isEqualToString:NSURLErrorDomain]) {
            switch (op.error.code) {
                case kCFURLErrorUnknown:
                case kCFURLErrorTimedOut:
                case kCFURLErrorCannotFindHost:
                case kCFURLErrorCannotConnectToHost:
                case kCFURLErrorNetworkConnectionLost:
                case kCFURLErrorDNSLookupFailed:
                case kCFURLErrorResourceUnavailable:
                case kCFURLErrorRequestBodyStreamExhausted:
                    isError = YES;
                    break;
            }
        }
    }
    
    return isError;
}

BOOL opIsRetryableKCSError(NSOperation<KCSNetworkOperation>* op)
{
    //kcs error KinveyInternalErrorRetry:
    //        statusCode: 500
    //        description: "The Kinvey server encountered an unexpected error. Please retry your request"
    
    return [op.response isKCSError] == YES &&
    ((op.response.code == 500 &&
      [[op.response jsonObject][@"error"] isEqualToString:@"KinveyInternalErrorRetry"]) ||
     op.response.code == 429);
}

- (void) retryOp:(NSOperation<KCSNetworkOperation>*)oldOp request:(NSURLRequest*)request
{
    NSUInteger newcount = oldOp.retryCount + 1;
    if (newcount == kMaxTries) {
        [self callCallback:oldOp request:request];
    } else {
        NSOperation<KCSNetworkOperation>* op = [[[oldOp class] alloc] initWithRequest:request];
        op.clientRequestId = oldOp.clientRequestId;
        op.retryCount = newcount;
        @weakify(op);
        op.completionBlock = ^() {
            @strongify(op);
            [self requestCallback:op request:request];
        };
        
        double delayInSeconds = 0.1 * pow(2, newcount - 1); //exponential backoff
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [queue addOperation:op];
        });
    }
}

- (void) callCallback:(NSOperation<KCSNetworkOperation>*)op request:(NSURLRequest*)request
{
    [_currentQueue addOperationWithBlock:^{
        op.response.originalURL = request.URL;
        NSError* error = nil;
        if (op.error) {
            error = [op.error errorByAddingCommonInfo];
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Network Client Error %@ [KinveyKit id: '%@']", error, op.clientRequestId);
        } else if ([op.response isKCSError]) {
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Server Error (%ld) %@ [KinveyKit id: '%@' %@]", (long)op.response.code, op.response.jsonObject, op.clientRequestId, op.response.headers);
            [self.credentials handleErrorResponse:op.response];
            error = [op.response errorObject];
        } else {
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Success (%ld) [KinveyKit id: '%@'] %@", (long)op.response.code, op.clientRequestId, op.response.headers);
        }
        error = [error updateWithInfo:@{kErrorKeyMethod : request.HTTPMethod}];
        self.completionBlock(op.response, error);
    }];
}


#pragma mark - Debug

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ [%@]", [super debugDescription], [self finalURL]];
}

@end
