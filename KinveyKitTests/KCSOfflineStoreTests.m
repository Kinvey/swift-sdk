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

@interface KCSAppdataStore ()
- (void) setReachable:(BOOL)r;
@end

@interface KCSOfflineStoreTests ()
{
    BOOL _shouldSaveCalled;
    BOOL _shouldSaveReturn;
}

@end

@implementation KCSOfflineStoreTests

- (void)setUp
{
    BOOL up = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(up, @"should be setup");
    
    _shouldSaveCalled = NO;
    _shouldSaveReturn = YES;
}

- (void) testErrorOnOffline
{
    NSLog(@"---------- starting");
    
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x"}];
    
    [store setReachable:NO];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertError(errorOrNil, KCSKinveyUnreachableError);
        NSArray* objs = [[errorOrNil userInfo] objectForKey:KCS_ERROR_UNSAVED_OBJECT_IDS_KEY];
        STAssertEquals((NSUInteger)1, (NSUInteger) objs.count, @"should have one unsaved obj, from above");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"%f", percentComplete);
    }];
    
    [self poll];
}

- (void) testWillSaveWhenGoBackOnline
{
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
    KCSOfflineStoreTests* o = self;
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x", KCSStoreKeyOfflineSaveDelegate : o}];
    
    [store setReachable:NO];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertError(errorOrNil, KCSKinveyUnreachableError);
        NSArray* objs = [[errorOrNil userInfo] objectForKey:KCS_ERROR_UNSAVED_OBJECT_IDS_KEY];
        STAssertEquals((int)1, objs.count, @"should have one unsaved obj, from above");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"%f", percentComplete);
    }];
    
    [self poll];
    
    self.done = NO;
    
    [store setReachable:YES];
    
    [self poll];
}

#pragma mark - Offline Save Delegate
- (BOOL)shouldSave:(id<KCSPersistable>)entity lastSaveTime:(NSDate *)timeSaved
{
    _shouldSaveCalled = YES;
    ASTTestClass* obj = entity;
    STAssertEquals((int)79000, obj.objCount, @"should have the right obj to save");
    self.done = YES;
    return _shouldSaveReturn;
}

@end
