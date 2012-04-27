//
//  KinveyKitNSURLTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitNSURLTests.h"
#import "NSURL+KinveyAdditions.h"

@implementation KinveyKitNSURLTests

- (void)testURLByAppendingQueryString
{
    // Test empty String + empty string
    NSURL *emptyURL = [NSURL URLWithString:@""];
    assertThat([emptyURL URLByAppendingQueryString:@""], is(equalTo(emptyURL)));
    
    
    // Test empty string + value
    NSURL *testURL = [NSURL URLWithString:@"?value"];
    assertThat([emptyURL URLByAppendingQueryString:@"value"], is(equalTo(testURL)));
    
    // Test Value + empty string
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    assertThat([testURL URLByAppendingQueryString:@""], is(equalTo(testURL)));
    

    // Test nil
    assertThat([testURL URLByAppendingQueryString:nil], is(equalTo(testURL)));

    
    // Test simple query
    NSURL *rootURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?test"];
    assertThat([rootURL URLByAppendingQueryString:@"test"], is(equalTo(testURL)));


    
    // Test double append
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?one=1&two=2"];
    
    assertThat([[rootURL URLByAppendingQueryString:@"one=1"] URLByAppendingQueryString:@"two=2"], is(equalTo(testURL)));
    
}

- (void)testURLWithUnencodedString
{
    NSString *unEncoded = @"!#$&'()*+,/:;=?@[]{} %";
    NSString *encoded = @"%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D%7B%7D%20%25";

    NSURL *one = [NSURL URLWithString:encoded];
    NSURL *two = [NSURL URLWithUnencodedString:unEncoded];
    
    assertThat(two, is(equalTo(one)));

}
@end
