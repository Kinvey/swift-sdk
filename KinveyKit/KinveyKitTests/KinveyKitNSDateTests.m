//
//  KinveyKitNSDateTests.m
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitNSDateTests.h"
#import "NSDate+ISO8601.h"
#import "KCSLogManager.h"

@implementation KinveyKitNSDateTests

// All code under test must be linked into the Unit Test bundle
- (void)testDates
{
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSString *ISO = [now stringWithISO8601Encoding];
    NSDate *then = [NSDate dateFromISO8601EncodedString:ISO];
    
    NSTimeInterval deltaDate = [now timeIntervalSinceDate:then];
    
    NSLog(@"Then: %@, Now: %@, delta: %f, inRange? %@", then, now, deltaDate, (fabs(deltaDate) < 0.001)?@"YES":@"NO");
    
    assertThat([NSNumber numberWithDouble:deltaDate], is(closeTo(0, 0.001)));
}

- (NSString *)nomillis:(NSString *)rfc3339DateTimeString
{
    NSDateFormatter *   rfc3339DateFormatter;
    NSLocale *          enUSPOSIXLocale;
    NSDate *            date;
    rfc3339DateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    date = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    
    return [rfc3339DateFormatter stringFromDate:date];
}


- (void)testMillis
{
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSString *ISO = [now stringWithISO8601Encoding];
    NSString *noM = [self nomillis:ISO];
    NSDate *then = [NSDate dateFromISO8601EncodedString:noM];
    
    NSTimeInterval deltaDate = [now timeIntervalSinceDate:then];
    
    NSLog(@"Then: %@, Now: %@, delta: %f, inRange? %@", then, now, deltaDate, (fabs(deltaDate) < 1)?@"YES":@"NO");
    
    assertThat([NSNumber numberWithDouble:deltaDate], is(closeTo(0, 1)));
}

@end
