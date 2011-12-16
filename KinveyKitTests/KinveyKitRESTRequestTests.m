//
//  KinveyKitRESTRequestTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/29/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyKitRESTRequestTests.h"
#import "KCSRESTRequest.h"
#import "KCSMockConnection.h"
#import "KCSMockURLConnection.h"

@implementation KinveyKitRESTRequestTests

// Defined in REST body
NSString *getLogDate(void); // Make compiler happy...
- (void)testDate
{
    NSLog(@"Date Header: %@", getLogDate());
}

// All code under test must be linked into the Unit Test bundle
- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}

- (void)testTest
{
    KCSMockConnection *connection = [[KCSMockConnection alloc] initWithConnection:[KCSMockURLConnection connectionWithRequest:nil delegate:self]];
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:@"/" usingMethod:kGetRESTMethod];
    [request mockRequestWithMockClass:[KCSMockConnection class]];
    [request start];
    STAssertFalse(request.isSyncRequest, @"Request should be MOCK, not Sync");
}

@end
