//
//  KCSKinveyUDID.m
//  KinveyKit
//
//  Created by Brian Wilson on 3/28/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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


#import "KCSKinveyUDID.h"
#import "KCSSecureUDID.h"

#import "KCSPlatformUtils.h"
#import <UIKit/UIKit.h>

// This "salt" is global for all KinveyKit apps, and it's locatable
// as a static string in the KinveyKit file, so can be extracted via
// a little work...
#define KCS_SALT_FOR_UDID @"0xdeadbeefcafebabe"

@implementation KCSKinveyUDID

+ (NSString *)uniqueIdentifier
{
    NSString* identifier = nil;
    if ([KCSPlatformUtils supportsVendorID]) {
        identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    if (identifier == nil) {
        identifier = [KCSKinveyUDID uniqueIdentifierFromSecureUDID];
    }
    return identifier;
}

+ (NSString *)uniqueIdentifierFromSecureUDID
{
    return [KCSSecureUDID UDIDForDomain:@"com.kinvey" usingKey:KCS_SALT_FOR_UDID];
}


@end
