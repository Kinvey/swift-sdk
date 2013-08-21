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


@interface KCSRequest2 ()
@end

@implementation KCSRequest2

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.name = @"com.kinvey.KinveyKit.RequestQueue";
}

- (void)start
{
    //TODO: mock server
    NSString* pingStr = @"http://v3yk1n.kinvey.com/appdata/kid10005";
    NSURL* pingURL = [NSURL URLWithString:pingStr];
    
    NSOperation* op = nil;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:pingURL];
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    headers[@"Content-Type"] = @"application/json";
    headers[@"Authorization"] = @"Basic a2lkMTAwMDU6OGNjZTk2MTNlY2I3NDMxYWI1ODBkMjA4NjNhOTFlMjA=";
    headers[@"X-Kinvey-Api-Version"] = @"3";
    [request setAllHTTPHeaderFields:headers];
    
    op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
    
    
    [queue addOperation:op];
    //Client - init from plist
    //client init from options
    //client init from params
}



@end
