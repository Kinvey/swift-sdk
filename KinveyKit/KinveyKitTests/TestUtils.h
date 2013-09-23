//
//  TestUtils.h
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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
#import <KinveyKit/KinveyKit.h>

#define STAssertNoError STAssertNil(errorOrNil,@"Should not get error: %@", errorOrNil);
#define STAssertNoError_ STAssertNil(error, @"Should not get error: %@", error);
#define STAssertError(error, cd) STAssertNotNil(error, @"should have an error"); STAssertEquals((int)cd, (int)[error code], @"error codes should match.");
#define STAssertObjects(cnt) STAssertNotNil(objectsOrNil,@"should get non-nil return objects"); \
                               STAssertEquals((int)[objectsOrNil count], (int)cnt, @"Expecting %i items", cnt);

#define KTAssertEqualsInt(x,y, desc) STAssertEquals((int)x,(int)y, desc)
#define KTAssertCount(c, obj) STAssertNotNil(obj, @"obj should be non-nil"); STAssertEquals((int)[obj count], (int)c, @"count did not match expectation")
#define KTAssertCountAtLeast(c, obj) STAssertTrue( [obj count] >= c, @"count (%i) should be at least (%i)", [obj count], c);
#define KTAssertEqualsDates(date1,date2) STAssertTrue([date1 isEqualToDate:date2], @"Dates should match.");

NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse);

@interface KCSUser (TestUtils)
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew;
@end

@interface SenTestCase (TestUtils)
@property (nonatomic) BOOL done;
- (BOOL) poll;
- (BOOL) poll:(NSTimeInterval)timeout;
- (KCSCompletionBlock) pollBlock;
@end

//@interface XCTestCase (TestUtils)
//@property (nonatomic) BOOL done;
//- (void) poll;
//- (KCSCompletionBlock) pollBlock;
//@end

@interface TestUtils : NSObject

+ (BOOL) setUpKinveyUnittestBackend;
+ (void) justInitServer;
+ (NSURL*) randomFileUrl:(NSString*)extension;

+ (KCSCollection*) randomCollection:(Class)objClass;
@end
