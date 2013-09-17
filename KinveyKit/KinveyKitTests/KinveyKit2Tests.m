//
//
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
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

#import "KinveyCoreInternal.h"
#import "KCSRequest2.h"

//TODO: remove
#import "ASTTestClass.h"

@interface KinveyKit2Tests : SenTestCase
//TODO: remove
@property (nonatomic, strong) NSMutableData* downloadedData;

@end




#import <objc/runtime.h>
@interface KinveyKit2Tests (KinveyKit2Tests)
@property (nonatomic) BOOL done;
- (BOOL) poll;
@end

@implementation KinveyKit2Tests (KinveyKit2Tests)
@dynamic done;
#define POLL_INTERVAL 0.05
#define MAX_POLL_COUNT 30 / POLL_INTERVAL

- (BOOL) poll
{
    int pollCount = 0;
    while (self.done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %4.2fs", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
    }
    if (pollCount == MAX_POLL_COUNT) {
        STFail(@"polling timed out");
    }
    return YES;
}

- (BOOL)done {
    return [objc_getAssociatedObject(self, @"doneval") boolValue];
}

- (void)setDone:(BOOL)newDone {
    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

#import "KCS_SBJson.h"

@interface KinveyKit2Tests (Temp) <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableData* downloadedData;
@end

@implementation KinveyKit2Tests

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

- (void) testX
{
    
    ASTTestClass* t = [[ASTTestClass alloc] init];
    t.objId = @"A";
    t.objCount = 123;
    
    NSLog(@"bc");
    
}

- (void) testExample
{
    //    KCSRequest2* a = [[KCSRequest2 alloc] init];
    //    [a start];
    // [self poll];
    STFail(@"NIY");
}

//- (void)testExample
//{
//    //TODO: mock server
//    NSString* pingStr = @"http://v3yk1n.kinvey.com/appdata/kid10005";
//    NSURL* pingURL = [NSURL URLWithString:pingStr];
//    
//    if ([KCSPlatformUtils supportsNSURLSession] == YES) {
//        KTNIY
//    } else {
//        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:pingURL];
//        
//        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
//        headers[@"Content-Type"] = @"application/json";
//        headers[@"Authorization"] = @"Basic a2lkMTAwMDU6OGNjZTk2MTNlY2I3NDMxYWI1ODBkMjA4NjNhOTFlMjA=";
//        headers[@"X-Kinvey-Api-Version"] = @"3";
//        [request setAllHTTPHeaderFields:headers];
//        
//        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
//        
//        self.downloadedData = [NSMutableData data];
//        
//        [connection start];
//    }
//    KTPollStart;
//    
//    //Client - init from plist
//    //client init from options
//    //client init from params
//}
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//    KTAssertNoError;
//    KTPollDone;
//}
//
//- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [self.downloadedData appendData:data];
//}
//
//- (void) connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    id obj = [[[KCS_SBJsonParser alloc] init] objectWithData:self.downloadedData];
//    if (obj != nil && [obj isKindOfClass:[NSDictionary class]]) {
//        NSString* appHello = obj[@"kinvey"];
//        NSString* kcsVersion = obj[@"version"];
//        
//        STAssertNotNil(appHello, @"should get a hello");
//        STAssertNotNil(kcsVersion, @"should get a version");
//    } else {
//        //TODO: is an error
//    }
//    NSLog(@"obj: %@", obj);
//    STAssertNotNil(obj, @"should have an object back");
//    KTPollDone;
//}


@end
