//
//  NSDate+ISO8601.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "NSDate+ISO8601.h"
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
    time_t time  = [self timeIntervalSince1970];
    struct tm t;
    localtime_r(&time, &t);

    char timestring[1024];
    int len = strftime(timestring, 1023, "%Y-%m-%dT%H:%M:%S%z", &t);
    
    if (len){
        return nil;
    }
    
    return [NSString stringWithCString:timestring encoding:NSUTF8StringEncoding];
}

+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string
{
    const char *str = [string UTF8String];
    struct tm time;
    strptime(str, "%Y-%m-%dT%H:%M:%S%z", &time);
   
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    NSDate* myDate = [df dateFromString:
                      [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d +0000",
                       time.tm_year+1900, time.tm_mon+1, time.tm_mday,
                       time.tm_hour, time.tm_min, time.tm_sec]
                      ];
    [df release];
    return myDate;
}

@end
