//
//  KCSLinkedDataStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSLinkedAppdataStoreTests.h"

#import <KinveyKit/KinveyKit.h>

#import "KCSResource.h"
#import "KCSLinkedAppdataStore.h"

#import "ASTTestClass.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"

static NSString* _collection;

@interface TestClass : ASTTestClass 
@property (nonatomic, retain) id resource;
@end

@implementation TestClass
@synthesize resource;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"resource" forKey:@"resource"];
    return newmap;
}

@end

@interface ReffedTestClass : TestClass
@property (nonatomic, retain) TestClass* other;
@property (nonatomic, retain) NSArray* arrayOfOthers;
@property (nonatomic, retain) NSSet* setOfOthers;
@property (nonatomic, retain) ReffedTestClass* thisOther;
@end
@implementation ReffedTestClass
@synthesize other, arrayOfOthers;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"otherK" forKey:@"other"];
    [newmap setValue:@"arrayOfOthersK" forKey:@"arrayOfOthers"];
    [newmap setValue:@"setOfOthersK" forKey:@"setOfOthers"];
    [newmap setValue:@"thisOtherK" forKey:@"thisOther"];
    return newmap;
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    return @{ @"otherK" : @"OtherCollection", @"arrayOfOthersK" : @"OtherCollection", @"setOfOthersK" : @"OtherCollection", @"thisOtherK" : _collection};
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_REFERENCE_MAP_KEY : @{@"arrayOfOthers" : [TestClass class], @"setOfOthers" : [TestClass class]}};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%i>", self.objCount];
}
@end

@interface NestingRefClass : TestClass
@property (nonatomic, retain) ReffedTestClass* relatedObject;
@end
@implementation NestingRefClass
@synthesize relatedObject;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"relatedObject" forKey:@"relatedObject"];
    return newmap;
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    return @{ @"relatedObject" : @"NestedOtherCollection", @"relatedObject.otherK" : @"OtherCollection"};
}

@end


@implementation KCSLinkedAppdataStoreTests


- (void) setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(loaded, @"should be loaded");
    
    collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    _collection =  collection.collectionName;
    collection.objectTemplate = [TestClass class];
    store = [KCSLinkedAppdataStore storeWithCollection:collection options:nil];
}

- (UIImage*) makeImage
{
    UIGraphicsBeginImageContext(CGSizeMake(500, 500));
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(50, 50, 400, 400)];
    [[UIColor yellowColor] setFill];
    [path fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) testOne
{
    TestClass* obj = [[TestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testTwo //TODO: check file name matches object
{
    TestClass* obj1 = [[TestClass alloc] init];
    obj1.objDescription = @"test two-1";
    obj1.resource = [self makeImage];
    
    TestClass* obj2 = [[TestClass alloc] init];
    obj2.objDescription = @"test two-2";
    obj2.resource = [self makeImage];
    
    NSMutableArray* progArray = [NSMutableArray array];
    self.done = NO;
    
    [store saveObject:[NSArray arrayWithObjects:obj1, obj2,  nil] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals(2, (int) [objectsOrNil count], @"Should have saved two objects");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
        [progArray addObject:[NSNumber numberWithDouble:percentComplete]];
    }];
    [self poll];
    
    for (int i = 1; i< progArray.count; i++) {
        STAssertTrue([[progArray objectAtIndex:i] doubleValue] > [[progArray objectAtIndex:i-1] doubleValue], @"progress should be monotonically increasing");
        STAssertTrue([[progArray objectAtIndex:i] doubleValue] <= 1.0, @"progres should be 0 to 1");
    }
}
//TODO: test with massive query string > 1 name = "1mB"
- (void) testLoad
{
    __block TestClass* obj = [[TestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        TestClass* savedObj = [objectsOrNil objectAtIndex:0];
        STAssertNotNil(savedObj.resource, @"need a resource filled out");
        STAssertTrue([savedObj.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        TestClass* loaded = [objectsOrNil objectAtIndex:0];
        STAssertNotNil(loaded.resource, @"need a resource filled out");
        STAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        
    }];
    [self poll];
}


- (void) testWithQuery
{
    __block TestClass* obj = [[TestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store queryWithQuery:[KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:obj.kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        TestClass* loaded = [objectsOrNil objectAtIndex:0];
        STAssertNotNil(loaded.resource, @"need a resource filled out");
        STAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
    }];
    [self poll];
    
}
//TODO: TEST1000, TEST MAGNITUTDE DIFFERENCE

TestClass* randomTestClass(NSString* description)
{
    TestClass* ref = [[[TestClass alloc] init] autorelease];
    ref.objDescription = description;
    ref.objCount = arc4random();
    return ref;
}
#define TestClass(x) randomTestClass([NSString stringWithFormat:@"%s - %i",__PRETTY_FUNCTION__,x])


- (void) testSavingWithOneKinveyRef
{ 
    TestClass* ref = TestClass(0);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.other = ref;

    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        TestClass* newRef = ret.other;
        STAssertEquals(newRef.objCount, ref.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        TestClass* newRef = ret.other;
        STAssertEquals(newRef.objCount, ref.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testSavingWithArrayOfKivneyRef
{
    TestClass* ref1 = TestClass(1);
    TestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.arrayOfOthers = @[ref1, ref2];
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        TestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        STAssertEquals(newRef.objCount, ref1.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        STAssertEquals(newRef.objCount, ref2.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithArrayOfKivneyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        STAssertEquals((int) [ret.arrayOfOthers count], (int)2, @"Should have two saved objects");
        TestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        STAssertEquals(newRef.objCount, ref1.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        STAssertEquals(newRef.objCount, ref2.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testSavingArrayOfTopRefs
{
    TestClass* ref1 = TestClass(1);
    TestClass* ref2 = TestClass(2);
    TestClass* ref3 = TestClass(3);
    
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Save array of arrays - 1";
    obj1.other = ref1;
    obj1.arrayOfOthers = @[ref2, ref3];
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Save array of arrays - 2";
    obj2.other = ref1;
    obj2.arrayOfOthers = @[ref2, ref3];
    obj2.objCount = 2;

    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");

        ReffedTestClass* ret = obj1;
        TestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        STAssertEquals(newRef.objCount, ref2.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        STAssertEquals(newRef.objCount, ref3.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];

    self.done = NO;
    done = -1;
    
    [store loadObjectWithID:@[[obj1 kinveyObjectId],[obj2 kinveyObjectId]] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        STAssertEquals((int) [ret.arrayOfOthers count], (int)2, @"Should have two saved objects");
        TestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        STAssertEquals(newRef.objCount, ref2.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        STAssertEquals(newRef.objCount, ref3.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];

}

- (void) testSavingWithSetOfKivneyRef
{
    TestClass* ref1 = TestClass(1);
    TestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.setOfOthers = [NSSet setWithArray:@[ref1, ref2]];
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    NSString* prefix = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        TestClass* newRef = [ret.setOfOthers anyObject];
        STAssertTrue([newRef isKindOfClass:[TestClass class]], @"Should get a TestClass back");
        STAssertTrue([newRef.objDescription hasPrefix:prefix], @"Should get our testclass back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithArrayOfKivneyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        TestClass* newRef = [ret.setOfOthers anyObject];
        STAssertTrue([newRef isKindOfClass:[TestClass class]], @"Should get a TestClass back");
        STAssertTrue([newRef.objDescription hasPrefix:prefix], @"Should get our testclass back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testRefsWithQuery
{
    TestClass* ref1 = TestClass(1);
    TestClass* ref2 = TestClass(2);
    TestClass* ref3 = TestClass(3);
    
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with a query - 1";
    obj1.other = ref1;
    obj1.arrayOfOthers = @[ref2, [NSNull null]];
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with a query - 2";
    obj2.other = ref1;
    obj2.arrayOfOthers = @[ref2, ref3];
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"query - 1" options:kKCSRegexpCaseInsensitive];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 1, @"should have loaded just one objects");

        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
};

- (void) testTwoAtSameLevel
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with intradependence - 1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with intradependence - 2";
    obj2.thisOther = obj1;

    self.done = NO;
    __block double done = -1;
    
    [store saveObject:@[obj1,obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
 
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            STAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
        }];
        STAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];

}

//same test as above, but in reverse order, so the owning object is saved before the contained object
- (void) testTwoAtSameLevelReverseOrder
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with intradependence,rev - 1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with intradependence,rev - 2";
    obj2.thisOther = obj1;
    
    self.done = NO;
    __block double done = -1;
    
    [store saveObject:@[obj2, obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"- 2" options:kKCSRegexpCaseInsensitive];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 1, @"should have loaded just one object");
        ReffedTestClass* newObj = [objectsOrNil objectAtIndex:0];
        STAssertEqualObjects(newObj.objId, obj2.objId, @"Should get back the right id");
        ReffedTestClass* ref = newObj.thisOther;
        STAssertTrue([ref isKindOfClass:[ReffedTestClass class]], @"Should be a ref class");
        STAssertEqualObjects(ref.objId, obj1.objId, @"should get back the right object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
}

- (void) testCircularRefOne
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 1, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            STAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
        }];
        STAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testCircularRefArray
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular (array) - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular (array) - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            STAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
            //TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''obj1.thisOther = obj2, obj2.thisOther = obj1
        }];
        STAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testCircularRefArrayNoPost
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular (array) - 1";
    obj1.objCount = 1;
    obj1.objId = @"OBJECT1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular (array) - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    obj2.objId = @"OBJECT2";
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            STAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
            //TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''obj1.thisOther = obj2, obj2.thisOther = obj1
        }];
        STAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testCircularChain
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular chain - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular chain - 2";
    obj2.objCount = 2;
    
    ReffedTestClass* obj3 = [[ReffedTestClass alloc] init];
    obj3.objDescription = @"Test circular chain - 3";
    obj3.objCount = 3;

    ReffedTestClass* obj4 = [[ReffedTestClass alloc] init];
    obj4.objDescription = @"Test circular chain - 4";
    obj4.objCount = 4;
    
    obj1.thisOther = obj2;
    obj2.thisOther = obj3;
    obj3.thisOther = obj4;
    obj4.thisOther = obj1;

    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 1, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSAscending]];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 4, @"should have loaded all four objects");
        ReffedTestClass* prime1 = [objectsOrNil objectAtIndex:0];
        ReffedTestClass* prime2 = [objectsOrNil objectAtIndex:1];
        ReffedTestClass* prime3 = [objectsOrNil objectAtIndex:2];
        ReffedTestClass* prime4 = [objectsOrNil objectAtIndex:3];
        STAssertEqualObjects(prime1.thisOther.objId, prime2.objId, @"Should get back the original reference object");
        STAssertEqualObjects(prime2.thisOther.objId, prime3.objId, @"Should get back the original reference object");
        STAssertEqualObjects(prime3.thisOther.objId, prime4.objId, @"Should get back the original reference object");
        STAssertEqualObjects(prime4.thisOther.objId, prime1.objId, @"Should get back the original reference object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testNestedReferences
{
    NestingRefClass* obj1 = [[NestingRefClass alloc] init];
    obj1.objCount = 1;
    obj1.objDescription = @"testNestedReferences : Top Object";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objCount = 2;
    obj2.objDescription = @"testNestedReferences : Middle Object";
    obj1.relatedObject = obj2;
    
    TestClass* obj3 = [[TestClass alloc] init];
    obj3.objCount = 3;
    obj3.objDescription = @"testNestedReferences : Bottom Object";
    obj2.other = obj3;
    
    self.done = NO;
    __block double done = -1;
    
    store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:collection.collectionName ofClass:[NestingRefClass class]] options:nil];
    [store saveObject:obj1 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = [objectsOrNil objectAtIndex:0];
        ReffedTestClass* newRef = ret.relatedObject;
        STAssertEquals(newRef.objCount, obj2.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;

    [store loadObjectWithID:[obj1 kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = [objectsOrNil objectAtIndex:0];
        ReffedTestClass* newRef = ret.relatedObject;
        STAssertEquals(newRef.objCount, obj2.objCount, @"Should be the same object back");
        TestClass* bottomRef = newRef.other;
        STAssertEquals(bottomRef.objCount, obj3.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];

    
}
//TODO: note different objs
//TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''
@end
