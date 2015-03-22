//
//  RequestConfigurationTestsObjc.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KinveyKit.h"
#import "TestUtils2.h"

@interface MyURLProtocol : NSURLProtocol

@end

@implementation MyURLProtocol

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return YES;
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

@end

@interface RequestConfigurationTestsObjc : XCTestCase

@property (nonatomic, strong) KCSCollection* collection;
@property (nonatomic, strong) KCSAppdataStore* store;

@end

@implementation RequestConfigurationTestsObjc

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    KCSRequestConfiguration* requestConfig = [KCSRequestConfiguration requestConfigurationWithClientAppVersion:@"1.0"
                                                                                    andCustomRequestProperties:@{@"lang" : @"fr"}];
    
    [self setupKCS:YES requestConfiguration:requestConfig];
    
    self.collection = [KCSCollection collectionFromString:@"city"
                                                  ofClass:[NSMutableDictionary class]];
    self.store = [KCSAppdataStore storeWithCollection:self.collection
                                              options:@{}];
    
    [NSURLProtocol registerClass:[MyURLProtocol class]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
    
    NSDictionary *obj = @{
        @"_id" : @"Boston",
        @"name" : @"Boston",
        @"state" : @"MA"
    };
    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    [self.store saveObject:obj
       withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        [expectationSave fulfill];
    }
         withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
