//
//  KCSMetadataTests.m
//  KinveyKit
//
//  Created by Michael Katz on 6/25/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSMetadataTests.h"
#import <KinveyKit/KinveyKit.h>

#import "TestUtils.h"
#import "ASTTestClass.h"
@interface KCSMetadataTests () <KCSUserActionDelegate>
@end

@implementation KCSMetadataTests

- (void) setUp
{
    [TestUtils setUpKinveyUnittestBackend];
    
}

- (void) testKinveyMetadata
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testKinveyMetdata";
    obj.objCount = 100;
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    STAssertNotNil(obj.meta, @"Should have had metadata popuplated");
    STAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    STAssertEqualObjects([obj.meta creatorId], [[[KCSClient sharedClient] currentUser] kinveyObjectId], @"this user should be the creator");
    
    [obj.meta setUsersWithReadAccess:[NSArray arrayWithObject:@"me!"]];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    NSArray* readers = [obj.meta usersWithReadAccess];
    STAssertEquals((int)1, (int) [readers count], @"should have one reader");
    STAssertEqualObjects(@"me!", [readers objectAtIndex:0], @"expecting set object");
}

- (void) testGloballyReadable
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testGloballyReadable";
    obj.objCount = __LINE__;
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:NO];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];

    STAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    STAssertEqualObjects([obj.meta creatorId], [[[KCSClient sharedClient] currentUser] kinveyObjectId], @"this user should be the creator");
    STAssertFalse([obj.meta isGloballyReadable], @"expecting to have set that value");
    
    [obj.meta setGloballyReadable:NO];
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    STAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    STAssertEqualObjects([obj.meta creatorId], [[[KCSClient sharedClient] currentUser] kinveyObjectId], @"this user should be the creator");
    STAssertFalse([obj.meta isGloballyReadable], @"expecting to have set that value");
    
    self.done = NO;
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:self forceNew:YES];
    [self poll];

    self.done = NO;
    [store loadObjectWithID:obj.kinveyObjectId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"Should have gotten an error");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
}

- (void) user:(KCSUser *)user actionDidCompleteWithResult:(KCSUserActionResult)result
{
    self.done = YES;
}

- (void)user:(KCSUser *)user actionDidFailWithError:(NSError *)error
{
    self.done = YES;
}

@end
