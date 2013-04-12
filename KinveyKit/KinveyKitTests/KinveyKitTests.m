//
//  KinveyKitTests.m
//  KinveyKitTests
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
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
