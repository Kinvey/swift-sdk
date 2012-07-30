//
//  KinveyKitConnectionResponseTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitConnectionResponseTests.h"
#import "KCSConnectionResponse.h"
#import "SBJson.h"

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
    
    assertThat([NSNumber numberWithInt:response.responseCode], is(equalToInt(200)));
    assertThat(response.responseData, is(data));
    assertThat(response.responseHeaders, is(header));
    assertThat(response.userData, is(userData));
    
    response = [KCSConnectionResponse connectionResponseWithCode:0
                                                    responseData:nil
                                                      headerData:nil 
                                                        userData:nil];
    
    assertThat([NSNumber numberWithInt:response.responseCode], is(equalToInt(0)));
    assertThat(response.responseData, is(nilValue()));
    assertThat(response.responseHeaders, is(nilValue()));
    assertThat(response.userData, is(nilValue()));
    
}

- (void)testThatInvalidResponseCodeGetsInternalError
{
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:-21
                                                                           responseData:nil
                                                                             headerData:nil
                                                                               userData:nil];
    
    assertThat([NSNumber numberWithInt:response.responseCode], is(equalToInt(-1)));

}

@end
