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
#import "TestUtils.h"

@interface KCSUser ()
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew;
@end


@implementation KCSReduceFunctionTests

- (void) clearAll
{
    __block NSMutableArray* allObjs = [NSMutableArray array];
    self.done = NO;
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"%@", errorOrNil);
        if (objectsOrNil != nil) {
            [allObjs addObjectsFromArray:objectsOrNil];
        }
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"clear all query all = %f",percentComplete);
    }];
    [self poll];
    
    [store removeObject:allObjs withCompletionBlock:[self pollBlock] withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"clear all delete = %f",percentComplete);
    }];
    [self poll];
}

- (void) setUp
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"should be up and running");
    
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = [ASTTestClass class];
    
    store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, KCSStoreKeyResource, nil]];
    
    //TODO: no need to clear all since it's a new collection each time[self clearAll];
    
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

- (ASTTestClass*)makeObject:(NSString*)desc count:(int)count
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    obj.objDescription = desc;
    obj.objCount = count;
    return obj;
}


- (void) testGroupByCOUNT
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue], 1, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 2, @"expecting two objects of 'two'");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupBySUM
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 20, @"expecting two objects of 'two'");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupBySUMNonNumeric
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objDescription"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],0, @"expecting 0 for a non-numeric");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        STAssertEquals([value intValue], 0, @"expecting 0 for a non-numeric");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupByMIN
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MIN:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the min for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], -30, @"expecting 10 as the min for objects of 'math'");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}


- (void) testGroupByMAX
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MAX:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the max for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], 100, @"expecting 100 as the max for objects of 'math'");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void) testGroupByAverage
{
    self.done = NO;
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction AVERAGE:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        STAssertEquals([value intValue],10, @"expecting 10 as the avg for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        STAssertEquals([value intValue], 24, @"expecting 24 as the avg for objects of 'math'");
        
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

//TODO: try sum for various types, string, etc


@end
