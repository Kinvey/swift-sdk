//
//  KCSMockServerTest.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "KCSMockServer.h"
#import "TestUtils2.h"

@interface KCSMockServerTest : SenTestCase
@property (nonatomic, strong) KCSMockServer* server;
@end

@implementation KCSMockServerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    _server = [[KCSMockServer alloc] init];

}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void) testNoURL
{
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n.kinvey.com/foo/kid1000/a/b/c"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 404);
}

- (void) testAppdataBasic
{
    NSDictionary* data = @{@"_id":@1, @"key":@"value"};
    KCSNetworkResponse* response = [KCSNetworkResponse MockResponseWith:200 data:data];
    [_server setResponse:response forRoute:@"/appdata/kid1000/collection/1"];
    KCSNetworkResponse* r1 = [_server responseForURL:@"http://foo.bar.com/appdata/kid1000/collection/1"];
    KTAssertNotNil(r1);
    KTAssertEqualsInt(r1.code, 200);
    STAssertEqualObjects(r1.jsonData, data, @"data should match previous");
    
}

@end
