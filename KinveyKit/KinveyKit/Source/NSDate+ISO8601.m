//
//  NSDate+ISO8601.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/23/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
#pragma clang diagnostic pop
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
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
#pragma clang diagnostic pop
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
