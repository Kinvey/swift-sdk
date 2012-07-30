//
//  KinveyKitPushTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitPushTests.h"
#import "KCSPush.h"

@implementation KinveyKitPushTests

/////////
// NB: This is really difficult to test as none of the backend stuff gets called
//     on apple's simulator, so we need to run the tests on a device, but then
//     they'll fail in CI, unless we check to see if we're on the simulator, but
//     then we don't test the routines at all...
//     Not sure how to fix this yet...
/////////

// All code under test must be linked into the Unit Test bundle
- (void)testSharedPushReturnsInitializedSingleton{
    KCSPush *push = [KCSPush sharedPush];
    assertThat(push, is(notNilValue()));
}


@end
