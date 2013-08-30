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

KCS_CONST_IMPL KCSRequestOptionUseMock = @"UseMock";
KCS_CONST_IMPL KCSRESTRouteAppdata = @"appdata";

#define kHeaderContentType @"Content-Type"
#define kHeaderAuthorization @"Authorization"

#define KCS_VERSION @"3"



@interface KCSRequest2 ()
@property (nonatomic) BOOL useMock;
@property (nonatomic, copy) KCSRequestCompletionBlock completionBlock;
@property (nonatomic, copy) NSString* contentType;
@end

@implementation KCSRequest2

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    [queue setName:@"com.kinvey.KinveyKit.RequestQueue"];
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion options:(NSDictionary*)options;
{
    KCSRequest2* request = [[KCSRequest2 alloc] init];
    request.useMock = [options[KCSRequestOptionUseMock] boolValue];
    request.completionBlock = completion;
    return request;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _contentType = @"application/json";
    }
    return self;
}


# pragma mark -

- (NSOperation*) start
{
    //TODO: mock server
    NSString* pingStr = @"http://v3yk1n.kinvey.com/appdata/kid10005";
    NSURL* pingURL = [NSURL URLWithString:pingStr];
    
    NSOperation<KCSNetworkOperation>* op = nil;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:pingURL];
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    headers[kHeaderContentType] = _contentType;
    headers[kHeaderAuthorization] = @"Basic a2lkMTAwMDU6OGNjZTk2MTNlY2I3NDMxYWI1ODBkMjA4NjNhOTFlMjA=";
    headers[@"X-Kinvey-Api-Version"] = KCS_VERSION;
    [request setAllHTTPHeaderFields:headers];
    
    if (_useMock == YES) {
        op = [[KCSMockRequestOperation alloc] initWithRequest:request];
    } else {
        op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
    }
    @weakify(op);
    op.completionBlock = ^() {
        //TODO: error/response
        @strongify(op);
        self.completionBlock(op.response, op.error);
    };
    
    [queue addOperation:op];
    //Client - init from plist
    //client init from options
    //client init from params
    return op;
}



@end
