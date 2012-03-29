//
//  KCSKinveyUDID.m
//  KinveyKit
//
//  Created by Brian Wilson on 3/28/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSKinveyUDID.h"
#import "KCSSecureUDID.h"
#import "KCSOpenUDID.h"

// This "salt" is global for all KinveyKit apps, and it's locatable
// as a static string in the KinveyKit file, so can be extracted via
// a little work...
#define KCS_SALT_FOR_UDID @"0xdeadbeefcafebabe"

@implementation KCSKinveyUDID

+ (NSString *)uniqueIdentifier
{
    return [KCSKinveyUDID uniqueIdentifierFromSecureUDID];
}


+ (NSString *)uniqueIdentifierFromOpenUDID
{
    return [KCSOpenUDID value];
}

+ (NSString *)uniqueIdentifierFromSecureUDID
{
    return [KCSSecureUDID UDIDForDomain:@"com.kinvey" salt:KCS_SALT_FOR_UDID];
}


@end
