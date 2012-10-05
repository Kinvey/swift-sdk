//
//  KinveyKitConnectionResponseTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitConnectionResponseTests.h"
#import "KCSConnectionResponse.h"
#import "KCS_SBJson.h"

@implementation KinveyKitConnectionResponseTests

// All code under test must be linked into the Unit Test bundle
- (void)testFactoryMethodGeneratesValidResponse{
    NSDictionary *header = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSDictionary *userData = [NSDictionary dictionaryWithObject:@"This is some Test Data" forKey:@"testData"];
    KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
    NSData *data = [writer dataWithObject:userData];
    
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:data
                                                                             headerData:header 
                                                                               userData:userData];
    
    STAssertEquals(response.responseCode, 200, @"expecting OK");
    STAssertEqualObjects(response.responseData, data, @"data should match");
    STAssertEqualObjects(response.responseHeaders, header, @"data should match");
    STAssertEqualObjects(response.userData, userData, @"data should match");

    
    response = [KCSConnectionResponse connectionResponseWithCode:0
                                                    responseData:nil
                                                      headerData:nil 
                                                        userData:nil];

    STAssertEquals(response.responseCode, 0, @"expecting 0");
    STAssertNil(response.responseData, @"");
    STAssertNil(response.responseHeaders, @"");
    STAssertNil(response.userData, @"");
}

- (void)testThatInvalidResponseCodeGetsInternalError
{
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:-21
                                                                           responseData:nil
                                                                             headerData:nil
                                                                               userData:nil];
    
    STAssertEquals(response.responseCode, -1, @"expecting -1");
}

@end
