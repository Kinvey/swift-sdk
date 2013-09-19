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
#define kHeaderContentType     @"Content-Type"
#define kHeaderApiVersion      @"X-Kinvey-Api-Version"
#define kHeaderClientMethod    @"X-Kinvey-Client-Method"
#define kHeaderResponseWrapper @"X-Kinvey-ResponseWrapper"

#define kHeaderValueJson @"application/json"

KCS_CONST_IMPL KCSRequestOptionClientMethod = kHeaderClientMethod;
KCS_CONST_IMPL KCSRequestOptionUseMock      = @"UseMock";
KCS_CONST_IMPL KCSRESTRouteAppdata          = @"appdata";
KCS_CONST_IMPL KCSRESTRouteUser             = @"user";
KCS_CONST_IMPL KCSRESTRouteRPC              = @"rpc";
KCS_CONST_IMPL KCSRestRouteTestReflection   = @"!reflection";

KCS_CONST_IMPL KCSRESTMethodDELETE = @"DELETE";
KCS_CONST_IMPL KCSRESTMethodGET    = @"GET";
KCS_CONST_IMPL KCSRESTMethodPATCH  = @"PATCH";
KCS_CONST_IMPL KCSRESTMethodPOST   = @"POST";
KCS_CONST_IMPL KCSRESTMethodPUT    = @"PUT";


#define KCS_VERSION @"3"

@interface KCSRequest2 ()
@property (nonatomic) BOOL useMock;
@property (nonatomic, copy) KCSRequestCompletionBlock completionBlock;
@property (nonatomic, copy) NSString* contentType;
@property (nonatomic) dispatch_queue_t dispatch_queue;
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

- (NSOperation*) start
{
    NSAssert(_route, @"should have route");
    NSAssert(self.credentials, @"should have credentials");
    DBAssert(self.options[KCSRequestOptionClientMethod], @"DB should set client method");
    
    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
    NSString* baseURL = [config baseURL];
    NSString* kid = config.appKey;
    
    NSArray* path = [@[self.route, kid] arrayByAddingObjectsFromArray:[_path arrayByPercentEncoding]];
    NSString* urlStr = [path componentsJoinedByString:@"/"];
    NSString* endpoint = [baseURL stringByAppendingString:urlStr];

    NSURL* url = [NSURL URLWithString:endpoint];
    
    _dispatch_queue = dispatch_get_current_queue();
    
    NSOperation<KCSNetworkOperation>* op = nil;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:[config.options[KCS_URL_CACHE_POLICY] unsignedIntegerValue]
                                                       timeoutInterval:[config.options[KCS_CONNECTION_TIMEOUT] doubleValue]];
    request.HTTPMethod = self.method;
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    headers[kHeaderContentType] = _contentType;
    headers[kHeaderAuthorization] = [self.credentials authString];
    headers[kHeaderApiVersion] = KCS_VERSION;
    headers[kHeaderResponseWrapper] = @"true";
    setIfValNotNil(headers[kHeaderClientMethod], self.options[KCSRequestOptionClientMethod]);

    KK2(enable these headers)
    //headers[@"User-Agent"] = [client userAgent];
    //headers[@"X-Kinvey-Device-Information"] = [client.analytics headerString];

    [request setAllHTTPHeaderFields:headers];
    //[request setHTTPShouldUsePipelining:_httpMethod != kKCSRESTMethodPOST];
    
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@", request.HTTPMethod, request.URL);
    
    if (_useMock == YES) {
        op = [[KCSMockRequestOperation alloc] initWithRequest:request];
    } else {
       
        if ([KCSPlatformUtils supportsNSURLSession]) {
            op = [[KCSNSURLSessionOperation alloc] initWithRequest:request];
        } else {
            op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
        }
    }
    
    @weakify(op);
    op.completionBlock = ^() {
        dispatch_async(_dispatch_queue, ^{
            @strongify(op);
            op.response.originalURL = url;
            NSError* error = nil;
            if (op.error) {                
                error = [op.error errorByAddingCommonInfo];
                KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Network Client Error %@", error);
            } else if ([op.response isKCSError]) {
                KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Server Error (%d) %@", op.response.code, op.response.jsonData);
                error = [op.response errorObject];
            } else {
                KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Success (%d)", op.response.code);
            }
            self.completionBlock(op.response, error);
        });
    };
    
    [queue addOperation:op];
    return op;
}



@end
