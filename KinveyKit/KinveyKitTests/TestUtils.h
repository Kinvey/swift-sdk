//
//  TestUtils.h
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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

NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse);

@interface KCSUser (TestUtils)
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew;
@end

@interface SenTestCase (TestUtils)
@property (nonatomic) BOOL done;
- (void) poll;
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
