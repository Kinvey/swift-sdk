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

@interface KCSNetworkResponse ()
@property (nonatomic) NSInteger code;
@property (nonatomic, copy) id jsonData;
@end

@implementation KCSNetworkResponse

+ (instancetype) MockResponseWith:(NSInteger)code data:(id)data
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = code;
    response.jsonData = data;
    return response;
}

@end

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


- (KCSNetworkResponse*) responseForURL:(NSString*)url
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 404;
    response.jsonData = @{
                          @"error": @"EntityNotFound",
                          @"description": @"This entity not found in the collection",
                          @"debug": @""
                          };

    
    url = [url stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSArray* components = [url pathComponents];
    if (components != nil && components.count >= 4) {
//        NSString* protocol = components[0];
//        NSString* host = components[1];
        NSString* route = components[2];
//        NSString* kid = components[3];
  
        NSDictionary* d = _routes[route];
        if (d) {
            for (int i = 4; i < components.count - 1; i++) {
                d = d[components[i]];
            }
            response = d[components[components.count-1]];
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

@end
