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
    assertThat([emptyString URLByAppendingQueryString:@""], is(equalTo(emptyURL)));

    // Test nil
    assertThat([emptyString URLByAppendingQueryString:nil], is(equalTo(emptyURL)));
    
    // Test empty string + value
    NSURL *testURL = [NSURL URLWithString:@"?value"];
    assertThat([emptyString URLByAppendingQueryString:@"value"], is(equalTo(testURL)));
    
    // Test Value + empty string
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    NSString *testString = [NSString stringWithString:@"http://www.kinvey.com/"];
    assertThat([testString URLByAppendingQueryString:@""], is(equalTo(testURL)));
    
    // Test simple query
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?test"];
    assertThat([testString URLByAppendingQueryString:@"test"], is(equalTo(testURL)));
    
    // Test double append
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?one=1&two=2"];
    assertThat([[testString stringByAppendingString:@"?one=1"] URLByAppendingQueryString:@"two=2"], is(equalTo(testURL)));

               
    
}

- (void)testStringByAppendingQueryString
{
    // Test empty String + empty string
    NSString *emptyString = [NSString string];
    assertThat([emptyString stringByAppendingQueryString:@""], is(equalTo(emptyString)));
    
    // Test empty string + value
    NSString *testURL = [NSString stringWithString:@"?value"];
    assertThat([emptyString stringByAppendingQueryString:@"value"], is(equalTo(testURL)));
    
    // Test Value + empty string
    testURL = [NSString stringWithString:@"http://www.kinvey.com/"];
    NSString *testString = [NSString stringWithString:@"http://www.kinvey.com/"];
    assertThat([testString stringByAppendingQueryString:@""], is(equalTo(testURL)));
    
    // Test simple query
    testURL = [NSString stringWithString:@"http://www.kinvey.com/?test"];
    assertThat([testString stringByAppendingQueryString:@"test"], is(equalTo(testURL)));

    // Test nil
    assertThat([testString stringByAppendingQueryString:nil], is(equalTo(testString)));
    

    
    // Test double append
    testURL = [NSString stringWithString:@"http://www.kinvey.com/?one=1&two=2"];
    assertThat([[testString stringByAppendingQueryString:@"one=1"] stringByAppendingQueryString:@"two=2"], is(equalTo(testURL)));

}

- (void)testPercentEncoding
{
    NSString *unEncoded = @"!#$&'()*+,/:;=?@[]{} %";
    NSString *encoded = @"%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D%7B%7D%20%25";
    
    assertThat([@"" stringByAppendingStringWithPercentEncoding:unEncoded], is(equalTo(encoded)));
}

@end
