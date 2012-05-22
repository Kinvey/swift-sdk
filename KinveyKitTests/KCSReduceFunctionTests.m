//
//  KCSReduceFunctionTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSReduceFunctionTests.h"

#import <KinveyKit/KinveyKit.h>

#import "ASTTestClass.h"

@interface KCSUser ()
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew;
@end


@implementation KCSReduceFunctionTests

- (void) setUp
{
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1667" withAppSecret:@"2495d9ae77a04604acf73876e9b84fff" usingOptions:nil];
    [[[KCSClient sharedClient] currentUser] logout];
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil forceNew:YES];
    
    //    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    
    done = NO;
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        STAssertTrue(result.pingWasSuccessful, result.description);
        done = YES;
    }];
    [self poll];
    
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = @"testObjects";
    collection.objectTemplate = [ASTTestClass class];
    
    store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, kKCSStoreKeyResource, nil]];
    
    __block NSMutableArray* allObjs = [NSMutableArray array];
    done = NO;
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"%@", errorOrNil);
        if (objectsOrNil != nil) {
            [allObjs addObjectsFromArray:objectsOrNil];
        }
        done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    [store removeObject:allObjs withCompletionBlock:[self pollBlock] withProgressBlock:nil];
    [self poll];
    
    
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"math" count:2]];
    [baseObjs addObject:[self makeObject:@"math" count:100]];
    [baseObjs addObject:[self makeObject:@"math" count:-30]];
    [store saveObject:baseObjs withCompletionBlock:[self pollBlock] withProgressBlock:nil];
    [self poll];

}


#define MAX_POLL_COUNT 20

- (void) poll
{
    int pollCount = 0;
    while (done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %i", pollCount);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        pollCount++;
    }
    //TODO: pollcount failure
    if (pollCount == MAX_POLL_COUNT) {
        STFail(@"polling timed out");
    }
}

- (KCSCompletionBlock) pollBlock
{
    done = NO;
    return [^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            STFail(@"%@", errorOrNil);
        }
        done = YES;
    } copy];
}

- (ASTTestClass*)makeObject:(NSString*)desc count:(int)count
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    obj.objDescription = desc;
    obj.objCount = count;
    return obj;
}


- (void) testGroupByCOUNT
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue], 1, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 2, @"expecting two objects of 'two'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupBySUM
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 20, @"expecting two objects of 'two'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupBySUMNonNumeric
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objDescription"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],0, @"expecting 0 for a non-numeric");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 0, @"expecting 0 for a non-numeric");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupByMIN
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MIN:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the min for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], -30, @"expecting 10 as the min for objects of 'math'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}


- (void) testGroupByMAX
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MAX:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the max for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], 100, @"expecting 100 as the max for objects of 'math'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupByAverage
{
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction AVERAGE:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the avg for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], 24, @"expecting 24 as the avg for objects of 'math'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
}

//TODO: try sum for various types, string, etc


@end
