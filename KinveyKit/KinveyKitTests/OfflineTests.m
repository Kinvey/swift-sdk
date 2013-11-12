//
//  OfflineTests.m
//  KinveyKit
//
//  Created by Michael Katz on 11/12/13.
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

#import <SenTestingKit/SenTestingKit.h>

#import "TestUtils2.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

@interface KCSUser (TestUtils)
+ (void) mockUser;
@end

@implementation KCSUser (TestUtils)
+ (void)mockUser
{
    KCSUser* user = [[KCSUser alloc] init];
    user.username = @"mock";
    user.password = @"mock";
    user.sessionAuth = @"mock";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = user;
#pragma clang diagnostic pop
}

@end


@interface OfflineDelegate : NSObject <KCSOfflineUpdateDelegate>
@property (atomic) BOOL shouldSaveCalled;
@property (atomic) BOOL willSaveCalled;
@property (atomic) BOOL didSaveCalled;
@property (nonatomic, copy) void (^callback)(void);
@end
@implementation OfflineDelegate

- (BOOL)shouldSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName lastAttemptedSaveTime:(NSDate *)saveTime
{
    self.shouldSaveCalled = YES;
    return YES;
}

- (void)willSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.willSaveCalled = YES;
}

- (void)didSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.didSaveCalled = YES;
    _callback();
}

@end

@interface OfflineTests : SenTestCase

@end

@implementation OfflineTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testBasic
{
    [KCSUser mockUser];
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"offlinetests"];
    [cache clearCaches];
    OfflineDelegate* delegate = [[OfflineDelegate alloc] init];
    delegate.callback = ^{self.done = YES;};
    
    KCSOfflineUpdate* update = [[KCSOfflineUpdate alloc] initWithCache:cache];
    update.delegate = delegate;
    update.useMock = YES;
    
    NSDictionary* entity = @{@"a":@"x"};
    [update addObject:entity route:@"R" collection:@"C" headers:@{KCSRequestLogMethod} method:@"POST" error:nil];
    
    [update start];
    self.done = NO;
    [self poll];
    
    STAssertEquals([cache unsavedCount], (int)0, @"should be zero");
}

@end
