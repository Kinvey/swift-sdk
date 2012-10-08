//
//  KinveyKitNSStringTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitNSStringTests.h"
#import "NSString+KinveyAdditions.h"

@implementation KinveyKitNSStringTests


- (void)testURLByAppendingQueryString
{
    // Test empty String + empty string
    NSURL *emptyURL = [NSURL URLWithString:@""];
    NSString *emptyString = [NSString string];
    STAssertEqualObjects([emptyString URLByAppendingQueryString:@""], emptyURL, @"");

    // Test nil
    STAssertEqualObjects([emptyString URLByAppendingQueryString:nil], emptyURL, @"");
    
    // Test empty string + value
    NSURL *testURL = [NSURL URLWithString:@"?value"];
    STAssertEqualObjects([emptyString URLByAppendingQueryString:@"value"], testURL, @"");
    
    // Test Value + empty string
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    NSString *testString = @"http://www.kinvey.com/";
    STAssertEqualObjects([testString URLByAppendingQueryString:@""], testURL, @"");
    
    // Test simple query
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?test"];
    STAssertEqualObjects([testString URLByAppendingQueryString:@"test"], testURL, @"");
    
    // Test double append
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?one=1&two=2"];
    STAssertEqualObjects([[testString stringByAppendingString:@"?one=1"] URLByAppendingQueryString:@"two=2"], testURL, @"");
}

- (void)testStringByAppendingQueryString
{
    // Test empty String + empty string
    NSString *emptyString = [NSString string];
    STAssertEqualObjects([emptyString stringByAppendingQueryString:@""], emptyString, @"");
    
    // Test empty string + value
    NSString *testURL = @"?value";
    STAssertEqualObjects([emptyString stringByAppendingQueryString:@"value"], testURL, @"");
    
    // Test Value + empty string
    testURL = @"http://www.kinvey.com/";
    NSString *testString = @"http://www.kinvey.com/";
    STAssertEqualObjects([testString stringByAppendingQueryString:@""], testURL, @"");
    
    // Test simple query
    testURL = @"http://www.kinvey.com/?test";
    STAssertEqualObjects([testString stringByAppendingQueryString:@"test"], testURL, @"");

    // Test nil
    STAssertEqualObjects([testString stringByAppendingQueryString:nil], testString, @"");
    

    // Test double append
    testURL = @"http://www.kinvey.com/?one=1&two=2";
    STAssertEqualObjects([[testString stringByAppendingQueryString:@"one=1"] stringByAppendingQueryString:@"two=2"], testURL, @"");
}

- (void)testPercentEncoding
{
    NSString *unEncoded = @"!#$&'()*+,/:;=?@[]{} %";
    NSString *encoded = @"%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D%7B%7D%20%25";
    
    STAssertEqualObjects([@"" stringByAppendingStringWithPercentEncoding:unEncoded], encoded, @"");
}

@end
