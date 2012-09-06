//
//  TestUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "TestUtils.h"
#import <KinveyKit/KinveyKit.h>
#import <SenTestingKit/SenTestingKit.h>
#import <objc/runtime.h>



NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse)
{
    return [NSDictionary dictionaryWithObjectsAndKeys:originalResponse, @"result", nil];
}


@implementation SenTestCase (TestUtils)
@dynamic done;
#define MAX_POLL_COUNT 20

- (void) poll
{
    int pollCount = 0;
    while (self.done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %i", pollCount);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:2];
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

- (KCSCompletionBlock) pollBlock
{
    self.done = NO;
    return [^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            STFail(@"%@", errorOrNil);
        }
        self.done = YES;
    } copy];
}



@end


@implementation TestUtils

+ (void) justInitServer
{
    //    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1880" withAppSecret:@"6414992408f04132bd467746f7ecbdcf" usingOptions:nil];
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid10005" withAppSecret:@"8cce9613ecb7431ab580d20863a91e20" usingOptions:nil];
    [[KCSClient sharedClient] setServiceHostname:@"v3yk1n"]; //TODO: encapsulate in TEST Utils
}

+ (BOOL) setUpKinveyUnittestBackend
{
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    [self justInitServer];
    __block BOOL loaded = NO;
    
    [[[KCSClient sharedClient] currentUser] logout];
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil forceNew:YES];
    
    SenTestCase* pollObj = [[[SenTestCase alloc] init]autorelease];
    pollObj.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        loaded = result.pingWasSuccessful;
        if (!loaded) {
            NSLog(@"ping error: %@", result.description);
        }
        pollObj.done = YES;
    }];
    [pollObj poll];
    
    return loaded;
}

+ (NSString*) uuid
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = nil;
    
    if (uuid){
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    return uuidString;
}

+ (NSURL*) randomFileUrl:(NSString*)extension
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString* path = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",[self uuid], extension]];
    return [NSURL fileURLWithPath:path];
}

+ (KCSCollection*) randomCollection:(Class)objClass
{
    KCSCollection* collection = [[[KCSCollection alloc] init] autorelease];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = objClass;
    return collection;
}

@end
