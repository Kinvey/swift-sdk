//
//  KCSMockServer.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import "KCSMockServer.h"
#import "KinveyCoreInternal.h"

@interface KCSMockServer ()
@property (nonatomic, strong) NSMutableDictionary* routes;
@end

@implementation KCSMockServer
- (instancetype) init
{
    self = [super init];
    if (self) {
        _routes = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedServer
{
    static KCSMockServer* server;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        server = [[KCSMockServer alloc] init];
    });
    return server;
}

- (KCSNetworkResponse*) make404
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 404;
    response.jsonData = @{
                          @"error": @"EntityNotFound",
                          @"description": @"This entity not found in the collection",
                          @"debug": @""
                          };

    return response;
}

- (KCSNetworkResponse*) make401
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 401;
    response.jsonData = @{
                          @"error": @"InvalidCredentials",
                          @"description": @"Invalid credentials. Please retry your request with correct credentials",
                          @"debug": @""
                          };
    
    return response;
}

- (KCSNetworkResponse*) makePingResponse
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 200;
    response.jsonData = @{
                          @"version": @"3.1.6-snapshot", //TODO: match from header
                          @"kinvey": @"Hello mock server", //TODO: pull from somewhere else
                          };
    return response;
}

- (KCSNetworkResponse*) makeReflectionResponse:(NSURLRequest*)request
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 200;
    if (request.HTTPBody) {
        response.jsonData = [[[KCS_SBJsonParser alloc] init] objectWithData:request.HTTPBody];
    }
    response.headers = request.allHTTPHeaderFields;
    return response;
}

- (KCSNetworkResponse*) responseForRequest:(NSURLRequest*)request
{
    NSString* url = [request.URL absoluteString];
    KCSNetworkResponse* response = [self make404];
    
    url = [url stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSArray* components = [url pathComponents];
    if (components != nil && components.count >= 4) {
//        NSString* protocol = components[0];
//        NSString* host = components[1];
        NSString* route = components[2];
        NSString* kid = components[3];
        if (self.appKey != nil && [kid isEqualToString:self.appKey] == NO) {
            return [self make401];
        }
        
        if ([route isEqualToString:KCSRestRouteTestReflection]) {
            return [self makeReflectionResponse:request];
        }
  
        if (components.count > 4) {
            NSDictionary* d = _routes[route];
            if (d) {
                for (int i = 4; i < components.count - 1; i++) {
                    d = d[components[i]];
                }
                response = d[components[components.count-1]];
            }
        } else {
            if ([route isEqualToString:KCSRESTRouteAppdata]) {
                return [self makePingResponse];
            }
        }
        
    }
    
    return response;
}

- (void) setResponse:(KCSNetworkResponse*)response forRoute:(NSString*)route
{
    route = [route stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSArray* components = [route pathComponents];
    if (components != nil && components.count >= 3) {
        NSString* route = components[0];
        //TODO: do we care about kid? NSString* kid = components[1];
        
        NSMutableDictionary* routeResponses = _routes[route];
        if (routeResponses == nil) {
            routeResponses = [NSMutableDictionary dictionary];
            _routes[route] = routeResponses;
        }
        
        NSMutableDictionary* ld = routeResponses;
        for (int i = 2; i < components.count - 1; i++) {
            NSMutableDictionary* d = ld[components[i]];
            if (d == nil) {
                d = [NSMutableDictionary dictionary];
                ld[components[i]] = d;
            }
            ld = d;
        }
        ld[components[components.count - 1]] = response;
    }
}

#pragma mark - debug

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ (%@)", [super debugDescription], self.appKey];
}

@end
