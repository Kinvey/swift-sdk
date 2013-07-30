//
//  PlatformUtilsTest.m
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>


//! should not have any other dependencies
#import "KCSPlatformUtils.h"

@interface PlatformUtilsTest : SenTestCase

@end

@implementation PlatformUtilsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testNSURLSessionSupport
{
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0) {
        STAssertFalse([KCSPlatformUtils supportsNSURLSession], @"No support pre iOS7");
    } else {
        STAssertTrue([KCSPlatformUtils supportsNSURLSession], @"Support iOS7 + ");
    }
}

@end
