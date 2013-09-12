//
//  KCSNetworkResponse.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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


#import "KCSNetworkResponse.h"
#import "KinveyCoreInternal.h"

#define kKinveyErrorDomain @"KinveyErrorDomain"

#define KCS_ERROR_DEBUG_KEY @"debug"
#define KCS_ERROR_DESCRIPTION_KEY @"description"
#define KCS_ERROR_KINVEY_ERROR_CODE_KEY @"error"

#define kKCSErrorCode @"kinveyErrorCode"

@interface KCSNetworkResponse ()
@end

@implementation KCSNetworkResponse

+ (instancetype) MockResponseWith:(NSInteger)code data:(id)data
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = code;
    response.jsonData = data;
    return response;
}

- (BOOL)isKCSError
{
    return self.code >= 400;
}

- (NSError*) errorObject
{
    NSDictionary* kcsErrorDict = [self jsonData];
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
    setIfValNotNil(userInfo[NSLocalizedDescriptionKey], kcsErrorDict[KCS_ERROR_DEBUG_KEY]);
    setIfValNotNil(userInfo[NSLocalizedFailureReasonErrorKey], kcsErrorDict[KCS_ERROR_DEBUG_KEY]);
    setIfValNotNil(userInfo[kKCSErrorCode], kcsErrorDict[KCS_ERROR_KINVEY_ERROR_CODE_KEY]);

    NSError* error = [NSError createKCSError:kKinveyErrorDomain code:self.code userInfo:userInfo];
    return error;
}

@end
