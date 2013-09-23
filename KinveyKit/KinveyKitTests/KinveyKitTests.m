//
//  KinveyKitTests.m
//  KinveyKitTests
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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


#import "KinveyKitTests.h"

#import "KinveyKit.h"
#import "TestUtils.h"

@implementation KinveyKitTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    STAssertTrue(YES, @"This is a test");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
- (void) testQuick
{
    KCSClient* client = [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_PTxdpyznUM" withAppSecret:@"5780da13d4d442daa54b8c3507d2a6a8" usingOptions:nil];
    KCSAppdataStore* s = [KCSAppdataStore storeWithOptions:@{KCSStoreKeyCollectionTemplateClass : [NSMutableDictionary class] , KCSStoreKeyCollectionName : @"meteor"}];
    
    self.done = NO;
    [s queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"%@," ,errorOrNil);
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}
#pragma clang diagnostic pop

@end
