//
//  NSDate+ISO8601.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "NSDate+ISO8601.h"
#import "KCSLogManager.h"
#import "KCSClient.h"

@implementation NSDate (ISO8601)


- (NSString *)stringWithISO8601Encoding
{
    NSLocale *          enUSPOSIXLocale;
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *dTmp = [df stringFromDate:self];
    KCSLogDebug(@"Date conversion: %@ => %@", self, dTmp);
    
    [df release];
    return dTmp;
}

+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string
{
    NSLocale *          enUSPOSIXLocale;
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate *myDate = [df dateFromString:string];
    [df release];
    return myDate;
}

@end
