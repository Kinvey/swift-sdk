//
//  KCSOfflineStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 8/7/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSOfflineStoreTests.h"
#import "TestUtils.h"
#import <KinveyKit/KinveyKit.h>
#import "ASTTestClass.h"
#import "KCSHiddenMethods.h"

@implementation KCSOfflineStoreTests

- (void)setUp
{
    BOOL up = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(up, @"should be setup");
}

- (void) testErrorOnOffline
{
    NSLog(@"---------- starting");
    
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{}];
    
    [store setReachable:NO];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertError(errorOrNil, KCSKinveyUnreachableError);
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"%f", percentComplete);
    }];
    
    [self poll];
}

@end
