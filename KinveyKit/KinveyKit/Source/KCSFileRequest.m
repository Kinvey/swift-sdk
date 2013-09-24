//
//  KCSFileRequest.m
//  KinveyKit
//
//  Created by Michael Katz on 9/24/13.
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


#import "KCSFileRequest.h"

#import "KinveyCoreInternal.h"
#import "KinveyFileStoreInteral.h"

#import "KCSNSURLCxnFileOperation.h"
#import "KCSNSURLSessionFileOperation.h"
#import "KCSMockFileOperation.h"
#import "KCSFileOperation.h"

@interface KCSFileRequest ()
@property (nonatomic) BOOL useMock;

@end

@implementation KCSFileRequest

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 2;
    [queue setName:@"com.kinvey.KinveyKit.FileRequestQueue"];
}


- (NSOperation*) downloadStream:(KCSFile*)intermediate
                        fromURL:(NSURL*)url
            alreadyWrittenBytes:(NSNumber*)alreadyWritten
                completionBlock:(StreamCompletionBlock)completionBlock
                  progressBlock:(KCSProgressBlock)progressBlock

{
//    NSAssert(_route, @"should have route");
//    NSAssert(self.credentials, @"should have credentials");
//    DBAssert(self.options[KCSRequestOptionClientMethod], @"DB should set client method");
    
    
    
    
    
//    
//    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
//    NSString* baseURL = [config baseURL];
//    NSString* kid = config.appKey;
//    
//    NSArray* path = [@[self.route, kid] arrayByAddingObjectsFromArray:[_path arrayByPercentEncoding]];
//    NSString* urlStr = [path componentsJoinedByString:@"/"];
//    NSString* endpoint = [baseURL stringByAppendingString:urlStr];
//    
//    NSURL* url = [NSURL URLWithString:endpoint];
//    
//    _currentQueue = [NSOperationQueue currentQueue];
//    
    NSOperation<KCSFileOperation>* op = nil;
//    
//    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
//                                                           cachePolicy:[config.options[KCS_URL_CACHE_POLICY] unsignedIntegerValue]
//                                                       timeoutInterval:[config.options[KCS_CONNECTION_TIMEOUT] doubleValue]];
//    request.HTTPMethod = self.method;
//    
//    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
//    headers[kHeaderContentType] = _contentType;
//    headers[kHeaderAuthorization] = [self.credentials authString];
//    headers[kHeaderApiVersion] = KCS_VERSION;
//    headers[kHeaderResponseWrapper] = @"true";
//    setIfValNotNil(headers[kHeaderClientMethod], self.options[KCSRequestOptionClientMethod]);
//    
//    KK2(enable these headers)
//    //headers[@"User-Agent"] = [client userAgent];
//    //headers[@"X-Kinvey-Device-Information"] = [client.analytics headerString];
//    
//    [request setAllHTTPHeaderFields:headers];
    //[request setHTTPShouldUsePipelining:_httpMethod != kKCSRESTMethodPOST];
    
    //    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@", request.HTTPMethod, request.URL);

/*
    if (_useMock == YES) {
        op = [[KCSMockFileOperation alloc] initWithRequest:request];
    } else {
        
        if ([KCSPlatformUtils supportsNSURLSession]) {
            op = [[KCSNSURLSessionFileOperation alloc] initWithRequest:request];
        } else {
            op = [[KCSNSURLCxnFileOperation alloc] initWithRequest:request];
        }
    }
 */
//    
//    @weakify(op);
//    op.completionBlock = ^() {
//        @strongify(op);
//        [self requestCallback:op request:request];
//    };
    
    [queue addOperation:op];
    return op;
}

@end
