//
//  KCSGenericRestTests.m
//  KinveyKit
//
//  Created by Michael Katz on 8/22/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSGenericRestTests.h"
#import "KCSGenericRESTRequest.h"
#import "KCSConnectionResponse.h"
#import "TestUtils.h"

@implementation KCSGenericRestTests

- (void) testGet
{
    NSString* url = @"http://developer.mbta.com/lib/RTCR/RailLine_8.json";
    self.done = NO;
    KCSGenericRESTRequest* req = [KCSGenericRESTRequest requestForResource:url usingMethod:kGetRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        NSDictionary* d = (NSDictionary*)[response jsonResponseValue];
        id e = [d objectForKey:@"UpdateDate"];
        NSLog(@"%@",[response jsonResponseValue]);
        STAssertNotNil(e, @"Should have update date");
        self.done = YES;
        
        
        NSArray* m = [d objectForKey:@"Messages"];
        
    } failureAction:^(NSError *error) {
        STAssertNil(error, @"shoul have no error: %@", error);
        self.done = YES;
    } progressAction:^(KCSConnectionProgress *progress) {
        //nothing
    }];
    [req start];
    [self poll];
}

@end
