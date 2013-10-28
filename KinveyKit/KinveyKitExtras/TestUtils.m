//
//  TestUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "TestUtils.h"
#import <KinveyKit/KinveyKit.h>
#import <SenTestingKit/SenTestingKit.h>
#import <objc/runtime.h>

#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"

NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse)
{
    return @{@"result" : originalResponse};
}


@implementation SenTestCase (TestUtils)
@dynamic done;
#define MAX_POLL_COUNT 20

- (BOOL) poll
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
    return YES;
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

+ (void) initCustom:(NSDictionary*)opts
{
    void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_TT1n4clp2M" withAppSecret:@"967c00679c004660bb356fdc92f436b2" usingOptions:opts];
    [[KCSClient sharedClient] setKinveyDomain:@"192.168.1.18"];
    [[KCSClient sharedClient] setServiceHostname:@""];
}

+ (void) initStaging:(NSDictionary*)opts
{
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid10005" withAppSecret:@"8cce9613ecb7431ab580d20863a91e20" usingOptions:opts];
    [[KCSClient sharedClient] setServiceHostname:STAGING_API];
    
}

+ (void) initProduction:(NSDictionary*)opts
{
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1880" withAppSecret:@"6414992408f04132bd467746f7ecbdcf" usingOptions:opts];
}

+ (void) justInitServer
{
    NSDictionary* opts = @{KCS_TWITTER_CLIENT_SECRET : @"u48B6AIxebTJwsDcZ3Si7SfvkJLeA9CRuR6VYtk0", KCS_TWITTER_CLIENT_KEY : @"LXRntT0sroPASCBM4p4Hw"};
    if (YES) {
        [self initStaging:opts];
    } else {
        [self initProduction:opts];
        [self initCustom:opts];
    }
}

+ (BOOL) setUpKinveyUnittestBackend
{
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    [self justInitServer];
    __block BOOL loaded = NO;

    SenTestCase* pollObj = [[SenTestCase alloc] init];
    
    [[[KCSClient sharedClient] currentUser] logout];
    pollObj.done = NO;
    [KCSUser registerUserWithUsername:nil withPassword:nil withCompletionBlock:^(KCSUser *user, NSError *errorOrNil,
                                                                                 KCSUserActionResult result) {
        NSAssert(errorOrNil == nil);
        pollObj.done = YES;
    } forceNew:YES];
    [pollObj poll];
    
    pollObj.done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        loaded = result.pingWasSuccessful;
        if (!loaded) {
            NSLog(@"ping error: %@", result.description);
        }
        pollObj.done = YES;
    }];
    [pollObj poll];
    
    
    loaded = loaded && [KCSUser activeUser] != nil;
    
    return loaded;
}

+ (NSString*) uuid
{
    return [NSString UUID];
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
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = objClass;
    return collection;
}

@end
