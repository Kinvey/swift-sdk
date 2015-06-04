//
//  MLIBZ_371_Tests.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-04.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KinveyKit/KinveyKit.h>

@interface MLIBZ_371_Tests : XCTestCase

@end

@implementation MLIBZ_371_Tests

- (void)setUp {
    [super setUp];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_-1WAs8Rh2"
                                                 withAppSecret:@"2f355bfaa8cb4f7299e914e8e85d8c98"
                                                  usingOptions:nil];
    
    XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
    
    [KCSUser loginWithUsername:@"4a51dbe2-cbfe-42c2-837b-0c81f533ac19" password:@"fb882daa-9168-4e00-a49c-57e35a9e74e4" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
    {
        XCTAssertNotNil(user);
        XCTAssertNil(errorOrNil);
        
        [expectationLogin fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)tearDown {
    [[KCSUser activeUser] logout];
    
    [super tearDown];
}

- (void)test {
    KCSCollection *collection = [KCSCollection collectionFromString:@"Pet" ofClass:[NSMutableDictionary class]];
    KCSCachedStore *store =[KCSCachedStore storeWithCollection:collection options:nil];
    
    __block NSString *petID = nil;
    
    XCTestExpectation* expectationCreate = [self expectationWithDescription:@"Create"];
    
    [store saveObject:@{@"name" : @"test"}
  withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        XCTAssertNotNil(objectsOrNil);
        XCTAssertNil(errorOrNil);
        
        if (objectsOrNil.count > 0) {
            XCTAssertNotNil(objectsOrNil[0][@"_id"]);
        }
        
        petID = objectsOrNil[0][@"_id"];
        
        [expectationCreate fulfill];
    }
    withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    [store loadObjectWithID:petID withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"Loaded pet %@", petID);
        NSMutableDictionary *loadedPet = objectsOrNil[0];
        [store saveObject:loadedPet withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (errorOrNil) {
                NSLog(@"Failed saving pet: %@", errorOrNil);
            } else {
                NSLog(@"Saving pet succeded");
            }
            
            [expectationSave fulfill];
            
        } withProgressBlock:nil];
        
        [expectationLoad fulfill];
        
    } withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:300 handler:nil];
}

@end
