//
//  KinveyCollectionStoreTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyAppdataStoreTests.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KinveyCollection.h"
#import "KCSAppdataStore.h"
#import "KinveyPing.h"
#import "KinveyUser.h"
#import "KCSReduceFunction.h"
#import "KCSGroup.h"

#import "ASTTestClass.h"

@interface KCSUser ()
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew;
@end


@implementation KinveyAppdataStoreTests

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
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, kKCSStoreKeyResource, nil]];
    
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
}

-(void)testSaveOne
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    
    
}

-(void)testSaveMany
{
    
}

- (void)testQuery
{
    
}

- (void)testQueryAll
{
    
}

- (void)testRemoveOne
{
    
}

- (void)testRemoveAll
{
    
}


- (void)testConfigure
{
    
}

- (void)testAuth
{
    
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


- (void) testGroupBy
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = @"testObjects";
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, kKCSStoreKeyResource, nil]];
    [store saveObject:baseObjs withCompletionBlock:[self pollBlock] withProgressBlock:nil];
    [self poll];
    
    
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

- (void) testGroupByWithCondition
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:30]];
    [baseObjs addObject:[self makeObject:@"two" count:70]];
    [baseObjs addObject:[self makeObject:@"one" count:5]];
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = @"testObjects";
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, kKCSStoreKeyResource, nil]];
    [store saveObject:baseObjs withCompletionBlock:[self pollBlock] withProgressBlock:nil];
    [self poll];
    
    
    done = NO;
    KCSQuery* condition = [KCSQuery queryOnField:@"objCount" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:10]];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue], NSNotFound, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 2, @"expecting two objects of 'two'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
    
    done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue], NSNotFound, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 100, @"expecting two objects of 'two'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
    
}

- (void) testGroupByMultipleFields
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:30]];
    [baseObjs addObject:[self makeObject:@"two" count:70]];
    [baseObjs addObject:[self makeObject:@"one" count:5]];
    [baseObjs addObject:[self makeObject:@"two" count:70]];
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = @"testObjects";
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, kKCSStoreKeyResource, nil]];
    [store saveObject:baseObjs withCompletionBlock:[self pollBlock] withProgressBlock:nil];
    [self poll];
    
    
    done = NO;
    [store group:[NSArray arrayWithObjects:@"objDescription", @"objCount", nil] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", [NSNumber numberWithInt:10], @"objCount", nil]];
        STAssertEquals([value intValue], 2, @"expecting two objects of 'one' & count == 0");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 1, @"expecting just one object of 'two', because this should bail after finding the first match of two");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
    
    done = NO;
    KCSQuery* condition = [KCSQuery queryOnField:@"objCount" usingConditional:kKCSGreaterThanOrEqual forValue:[NSNumber numberWithInt:10]];
    [store group:[NSArray arrayWithObjects:@"objDescription", @"objCount", nil] reduce:[KCSReduceFunction SUM:@"objCount"] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", [NSNumber numberWithInt:10], @"objCount", nil]];
        STAssertEquals([value intValue], 20, @"expecting to have sumed objects of 'one' and count == 10");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 10, @"expecting just the first obj of 'two'");
        
        done = YES;
    } progressBlock:nil];
    [self poll];
    
}

@end
