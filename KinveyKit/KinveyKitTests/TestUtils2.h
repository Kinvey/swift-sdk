//
//  TestUtils2.h
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


#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

#define KTAssertNoError STAssertNil(error, @"Should not get an error: %@", error);

#define KTAssertNotNil(x) STAssertNotNil(x, @#x" should not be nil.");
#define KTAssertEqualsInt(x,y) STAssertEquals((int)x,(int)y, @#x" != "#y);
#define KTAssertCount(c, obj) STAssertNotNil(obj, @#obj" should be non-nil"); STAssertEquals((int)[obj count], (int)c, @"count did not match expectation");
#define KTAssertCountAtLeast(c, obj) STAssertTrue( [obj count] >= c, @"count (%i) should be at least (%i)", [obj count], c);
#define KTAssertLengthAtLeast(obj, c) STAssertTrue( [obj length] >= c, @"count (%i) should be at least (%i)", [obj length], c);
#define KTAssertEqualsDates(date1,date2) STAssertTrue([date1 isEqualToDate:date2], @"Dates should match.");

#define KTNIY STFail(@"'%s' Not Implemented Yet.", __PRETTY_FUNCTION__);


#define KTPollDone self.done = YES;
#define KTPollStart self.done = NO; STAssertTrue([self poll], @"polling timed out");

@protocol KCSCredentials;
id<KCSCredentials> mockCredentails();

@interface SenTestCase (TestUtils2)
@property (nonatomic) BOOL done;
- (BOOL) poll;
- (void) setupKCS;
@end

@interface TestUtils2 : NSObject

@end
