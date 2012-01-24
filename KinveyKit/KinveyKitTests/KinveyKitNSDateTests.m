//
//  KinveyKitNSDateTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
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
    KCSLogDebug(@"Then: %@, Now: %@, delta: %d, inRange? %s", then, now, deltaDate, (fabs(deltaDate) < 0.001)?"YES":"NO");
    
    assertThat([NSNumber numberWithDouble:deltaDate], is(closeTo(0, 0.001)));
}

@end
