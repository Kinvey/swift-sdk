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

//    time_t now = time(NULL);
//    struct tm *t = gmtime(&now);
//    
//    char timestring[MAX_DATE_STRING_LENGTH_K];
//    
//    int len = strftime(timestring, MAX_DATE_STRING_LENGTH_K - 1, "%a, %d %b %Y %T %Z", t);
//    assert(len < MAX_DATE_STRING_LENGTH_K);
//    
//    return [NSString stringWithCString:timestring encoding:NSASCIIStringEncoding];


- (NSString *)stringWithISO8601Encoding
{
//    time_t time  = [self timeIntervalSince1970];
//    struct tm t;
//    gmtime_r(&time, &t);
//
//    char timestring[1024];
//    int len = strftime(timestring, 1023, "%Y-%m-%dT%H:%M:%S%z", &t);
//    
//    if (len == 0){
//        return nil;
//    }
//
    NSLocale *          enUSPOSIXLocale;
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *dTmp = [df stringFromDate:self];
    
//    NSString *dTmp = [NSString stringWithCString:timestring encoding:NSUTF8StringEncoding];
    KCSLogDebug(@"Date conversion: %@ => %@", self, dTmp);
    
    [df release];
    return dTmp;
}

+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string
{
//    const char *str = [string UTF8String];
//    struct tm time;
//    strptime(str, "%Y-%m-%dT%H:%M:%S%z", &time);

    NSLocale *          enUSPOSIXLocale;
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:enUSPOSIXLocale];
    [df setDateFormat:[[KCSClient sharedClient] dateStorageFormatString]];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDate *myDate = [df dateFromString:string];
    
//    NSDate* myDate = [df dateFromString:
//                      [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d",
//                       time.tm_year+1900, time.tm_mon+1, time.tm_mday,
//                       time.tm_hour, time.tm_min, time.tm_sec]
//                      ];
    [df release];
    return myDate;
}

@end
