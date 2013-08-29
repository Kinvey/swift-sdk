//
//  TestUtils2.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "TestUtils2.h"
#import <objc/runtime.h>

#define POLL_INTERVAL 0.05
#define MAX_POLL_COUNT 30 / POLL_INTERVAL

@implementation SenTestCase (TestUtils2)
@dynamic done;

- (BOOL) poll
{
    int pollCount = 0;
    while (self.done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %4.2fs", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
    }
    return pollCount == MAX_POLL_COUNT;
}

- (BOOL)done {
    return [objc_getAssociatedObject(self, @"doneval") boolValue];
}

- (void)setDone:(BOOL)newDone {
    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation TestUtils2

@end
