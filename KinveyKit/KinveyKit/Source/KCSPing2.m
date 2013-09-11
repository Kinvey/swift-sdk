//
//  KCSPing2.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
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


#import "KCSPing2.h"
#import "KinveyCoreInternal.h"

@implementation KCSPing2

+ (void)pingKinveyWithBlock:(KCSPingBlock2)completion
{
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSDictionary* appInfo = nil;
        if (!error) {
            if ([response isKCSError]) {
                error = [response errorObject];
            } else {
                appInfo = [response jsonData];
            }
        }
        completion(appInfo, error);
    } options:nil];
    [request start];
}

@end
