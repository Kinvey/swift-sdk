//
//  KinveyKitPushTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KinveyKitPushTests.h"
#import "KCSPush.h"
#import "KinveyUser.h"
#import "TestUtils.h"
#import "NSString+KinveyAdditions.h"

@implementation KinveyKitPushTests

/////////
// NB: This is really difficult to test as none of the backend stuff gets called
//     on apple's simulator, so we need to run the tests on a device, but then
//     they'll fail in CI, unless we check to see if we're on the simulator, but
//     then we don't test the routines at all...
//     Not sure how to fix this yet...
/////////

// All code under test must be linked into the Unit Test bundle
- (void)setUp
{
    STAssertTrue([TestUtils setUpKinveyUnittestBackend], @"should be set up");
}

- (void)testSharedPushReturnsInitializedSingleton{
    KCSPush *push = [KCSPush sharedPush];
    STAssertNotNil(push, @"should have a push value");
}

- (void) testAddTokenNormalFlow
{
    KCSUser* myUser = [KCSUser activeUser];
    STAssertNotNil(myUser, @"start with valid user");
    
    NSSet* tokens = myUser.deviceTokens;
    STAssertNotNil(tokens, @"should have no token");
    KTAssertCount(0, tokens);
    
    NSString* token = @"d4011af80d8cc2623f361d074a3c0a63162cc524bd18c4c07fbe05ebd074c621";
    NSMutableData *tokenData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < token.length / 2; i++) {
        byte_chars[0] = [token characterAtIndex:i*2];
        byte_chars[1] = [token characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [tokenData appendBytes:&whole_byte length:1];
    }
    
    self.done = NO;
    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:tokenData completionBlock:^(BOOL success, NSError *error) {
        STAssertNoError_;
        STAssertTrue(success, @"should register new token");
        self.done = YES;
    }];
    [self poll];
    
    //Test that local user was updated
    
    STAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
    NSSet* postTokens = myUser.deviceTokens;
    STAssertNotNil(postTokens, @"should have no token");
    KTAssertCount(1, postTokens);
    NSString* setToken = [postTokens anyObject];
    STAssertEqualObjects(setToken, token, @"token was set");
    
    //Test that server object was updated
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    self.done = NO;
    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertObjects(1)
        KCSUser* loadedUser = objectsOrNil[0];
        
        NSSet* loadedTokens = loadedUser.deviceTokens;
        STAssertNotNil(loadedTokens, @"should have no token");
        KTAssertCount(1, loadedTokens);
        NSString* loadedToken = [loadedTokens anyObject];
        STAssertEqualObjects(loadedToken, token, @"token was set");
        
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testUserGetsTokenIfPreRegistered
{
    STFail(@"NIY");
}

- (void) testRemoveNormalFlow
{
    STFail(@"NIY");
}

- (void) testAddNewDoesntKillOld
{
    STFail(@"NIY");
}

- (void) testemoveDoesntKillOld
{
    STFail(@"NIY");
}

@end
