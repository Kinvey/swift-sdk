//
//  NSDate+ISO8601.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/23/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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


#import "NSDate+ISO8601.h"
#import "KCSLogManager.h"
#import "KCSClient.h"

@implementation NSDate (ISO8601)

- (NSString *)stringWithISO8601Encoding
{
    NSLocale* enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString* dateFormat = [[KCSClient sharedClient] dateStorageFormatString];
#pragma clang diagnostic pop
    if (!dateFormat) {
        KK2(cleanup)
        dateFormat =  @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'";
    }

    [df setDateFormat:dateFormat];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *dTmp = [df stringFromDate:self];
    return dTmp;
}

+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string
{
    NSLocale* enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString* dateFormat = [[KCSClient sharedClient] dateStorageFormatString];
#pragma clang diagnostic pop
    if (!dateFormat) {
        KK2(cleanup)
        dateFormat =  @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'";
    }
    
    [df setDateFormat:dateFormat];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate *myDate = [df dateFromString:string];
    if (!myDate) {
        //The string might not have milliseconds, try again w/o them
        [df setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        myDate = [df dateFromString:string];
    }
    return myDate;
}

@end
