//
//  KCSRequest.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSRequest.h"

#import "KCSServerService.h"

static NSString* kGETMethod = @"GET";
static NSString* kPUTMethod = @"PUT";
static NSString* kPOSTMethod = @"POST";
static NSString* kDELETEMethod = @"DELETE";

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


- (void)run:(void (^)(NSData* data, NSError* error))runBlock
{
    //TODO
    id <KCSService> service = [[KCSServerService alloc] init];
    [service startRequest:self];
}

- (NSString*) methodName
{
    switch (_httpMethod) {
        case kKCSRESTMethodGET:
            return kGETMethod;
            break;
        case kKCSRESTMethodPUT:
            return kPUTMethod;
            break;
        case kKCSRESTMethodPOST:
            return kPOSTMethod;
            break;
        case kKCSRESTMethodDELETE:
            return kDELETEMethod;
            break;
    }
}

- (NSURLRequest*) nsurlRequest
{
    NSString* urlStr = @"";
    
    NSURL* url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url]; //TODO cache & timeout
    request.HTTPMethod = [self methodName];
    
    return request;
}

@end

@implementation KCSCacheRequest

@end
