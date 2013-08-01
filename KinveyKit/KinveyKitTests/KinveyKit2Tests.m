//
//
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "KinveyCoreInternal.h"

@interface KinveyKit2Tests : SenTestCase
//TODO: remove
@property (nonatomic, strong) NSMutableData* downloadedData;

@end


#define KTNIY STFail(@"Not Implemented Yet.");
#define KTPollDone self.done = YES;
#define KTPollStart self.done = NO; [self poll];
#define KTAssertNoError STAssertNil(error, @"Should not get an error: %@", error);

#import <objc/runtime.h>
@interface KinveyKit2Tests (KinveyKit2Tests)
@property (nonatomic) BOOL done;
- (void) poll;
@end

@implementation KinveyKit2Tests (KinveyKit2Tests)
@dynamic done;
#define POLL_INTERVAL 0.05
#define MAX_POLL_COUNT 30 / POLL_INTERVAL

- (void) poll
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

- (void)testExample
{
    //TODO: mock server
    NSString* pingStr = @"http://v3yk1n.kinvey.com/appdata/kid10005";
    NSURL* pingURL = [NSURL URLWithString:pingStr];
    
    if ([KCSPlatformUtils supportsNSURLSession] == YES) {
        KTNIY
    } else {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:pingURL];
        
        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
        headers[@"Content-Type"] = @"application/json";
        headers[@"Authorization"] = @"Basic a2lkMTAwMDU6OGNjZTk2MTNlY2I3NDMxYWI1ODBkMjA4NjNhOTFlMjA=";
        headers[@"X-Kinvey-Api-Version"] = @"3";
        [request setAllHTTPHeaderFields:headers];
        
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        self.downloadedData = [NSMutableData data];
        
        [connection start];
    }
    KTPollStart;
    
    //Client - init from plist
    //client init from options
    //client init from params
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    KTAssertNoError;
    KTPollDone;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    id obj = [[[KCS_SBJsonParser alloc] init] objectWithData:self.downloadedData];
    NSLog(@"obj: %@", obj);
    STAssertNotNil(obj, @"should have an object back");
    KTPollDone;
}


@end
