//
//  KCSLinkedDataStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012-2014 Kinvey. All rights reserved.
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


#import "KCSLinkedAppdataStoreTests.h"

#import <KinveyKit/KinveyKit.h>

#import "KCSFile.h"
#import "KCSLinkedAppdataStore.h"

#import "ASTTestClass.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"

static NSString* _collectionName;

@interface LinkedTestClass : ASTTestClass
@property (nonatomic, retain) id resource;
@end

@implementation LinkedTestClass

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    newmap[@"resource"] = @"resource";
    return newmap;
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    return @{@"resource" : KCSFileStoreCollectionName};
}

@end

@interface LinkedTestClassWithMeta : LinkedTestClass
@property (nonatomic, retain) KCSMetadata* meta;
@end
@implementation LinkedTestClassWithMeta

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    newmap[@"meta"] = KCSEntityKeyMetadata;
    return newmap;
}


@end

@interface UserRefTestClass : LinkedTestClass
@property (nonatomic, retain) KCSUser* auser;

@end

@implementation UserRefTestClass

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"auserK" forKey:@"auser"];
    return newmap;
}

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"auserK"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"auserK" : KCSUserCollectionName}];
    return map;
}
@end

@interface ReffedTestClass : LinkedTestClass
@property (nonatomic, retain) LinkedTestClass* other;
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

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"otherK",@"arrayOfOthersK",@"setOfOthersK",@"thisOtherK"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"otherK" : @"OtherCollection", @"arrayOfOthersK" : @"OtherCollection", @"setOfOthersK" : @"OtherCollection", @"thisOtherK" : _collectionName}];
    return map;
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_REFERENCE_MAP_KEY : @{@"arrayOfOthers" : [LinkedTestClass class], @"setOfOthers" : [LinkedTestClass class]}};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%i>", self.objCount];
}
@end

@interface NestingRefClass : LinkedTestClass
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

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"relatedObject"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"relatedObject" : @"NestedOtherCollection", @"relatedObject.otherK" : @"OtherCollection"}];
    return map;
}

@end

@interface NoSaveTestClass : LinkedTestClass
@property (nonatomic, retain) ReffedTestClass* relatedObject;
@end
@implementation NoSaveTestClass
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
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"relatedObject" : @"NestedOtherCollection", @"relatedObject.otherK" : @"OtherCollection"}];
    return map;
}

@end


@implementation KCSLinkedAppdataStoreTests


- (void) setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(loaded, @"should be loaded");
    
    _collection = [[KCSCollection alloc] init];
    _collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    _collectionName =  _collection.collectionName;
    _collection.objectTemplate = [LinkedTestClass class];
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

- (void) testOneLinkedFile
{
    LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* obj = objectsOrNil[0];
        STAssertNotNil(obj, @"should not be nil obj");
        STAssertNotNil(obj.resource, @"should still have an image");
        STAssertTrue([obj.resource isKindOfClass:[UIImage class]], @"Should still be an image");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testTwoFiles //TODO: check file name matches object
{
    LinkedTestClass* obj1 = [[LinkedTestClass alloc] init];
    obj1.objDescription = @"test two-1";
    obj1.resource = [self makeImage];
    
    LinkedTestClass* obj2 = [[LinkedTestClass alloc] init];
    obj2.objDescription = @"test two-2";
    obj2.resource = [self makeImage];
    
    NSMutableArray* progArray = [NSMutableArray array];
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
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
        STAssertTrue([progArray[i] doubleValue] >= [progArray[i-1] doubleValue], @"progress should be monotonically increasing");
        STAssertTrue([progArray[i] doubleValue] <= 1.0, @"progres should be 0 to 1");
    }
}

- (void) testLoad
{
    __block LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* savedObj = [objectsOrNil objectAtIndex:0];
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
        
        LinkedTestClass* loaded = [objectsOrNil objectAtIndex:0];
        STAssertNotNil(loaded.resource, @"need a resource filled out");
        STAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        
    }];
    [self poll];
}

- (void) testLinkedFilePreservesObjectMetadata
{
    __block LinkedTestClassWithMeta* obj = [[LinkedTestClassWithMeta alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:YES];
    
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    KCSAppdataStore* metaStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    //NOTE: this is highly tied to the implmentation!, not necessary for this test
    NSString* fileId = [NSString stringWithFormat:@"%@-%@-%@",_collectionName,obj.objId,@"resource"];
    self.done = NO;
    [metaStore loadObjectWithID:fileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertCount(1, objectsOrNil);
        KCSFile* thefile = objectsOrNil[0];
        KCSMetadata* filesMetadata = thefile.metadata;
        STAssertNotNil(filesMetadata, @"Should have metadata");
        STAssertTrue(filesMetadata.isGloballyReadable, @"Should have inherited global write");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}


- (void) testWithQuery
{
    __block LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
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
        
        LinkedTestClass* loaded = [objectsOrNil objectAtIndex:0];
        STAssertNotNil(loaded.resource, @"need a resource filled out");
        STAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
    }];
    [self poll];
    
}
//TODO: TEST1000, TEST MAGNITUTDE DIFFERENCE

LinkedTestClass* randomTestClass(NSString* description)
{
    LinkedTestClass* ref = [[LinkedTestClass alloc] init];
    ref.objDescription = description;
    ref.objCount = arc4random();
    return ref;
}
#define TestClass(x) randomTestClass([NSString stringWithFormat:@"%s - %i",__PRETTY_FUNCTION__,x])


- (void) testSavingWithOneKinveyRef
{ 
    LinkedTestClass* ref = TestClass(0);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.other = ref;

    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
        STAssertNotNil(newRef, @"should be a valid object");
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
        LinkedTestClass* newRef = ret.other;
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
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.arrayOfOthers = @[ref1, ref2];
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
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
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
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
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    LinkedTestClass* ref3 = TestClass(3);
    
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");

        ReffedTestClass* ret = obj1;
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        STAssertEquals(newRef.objCount, ref2.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        STAssertEquals(newRef.objCount, ref3.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];

    self.done = NO;
    done = -1;
    
    [store loadObjectWithID:@[[obj1 kinveyObjectId],[obj2 kinveyObjectId]] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = objectsOrNil[0];
        STAssertEquals((int) [ret.arrayOfOthers count], (int)2, @"Should have two saved objects");
        LinkedTestClass* newRef = ret.arrayOfOthers[0];
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
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.setOfOthers = [NSSet setWithArray:@[ref1, ref2]];
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    NSString* prefix = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = [ret.setOfOthers anyObject];
        STAssertTrue([newRef isKindOfClass:[LinkedTestClass class]], @"Should get a TestClass back");
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
        LinkedTestClass* newRef = [ret.setOfOthers anyObject];
        STAssertTrue([newRef isKindOfClass:[LinkedTestClass class]], @"Should get a TestClass back");
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
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    LinkedTestClass* ref3 = TestClass(3);
    
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    self.done = NO;
    done = -1;
    
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"^Test with.*1"];
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1,obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj2, obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
    
    
    self.done = NO;
    done = -1;
    
    KCSLinkedAppdataStore* store2 = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"^.*- 2"];
    [store2 queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 1, @"should have loaded just one object");
        ReffedTestClass* newObj = objectsOrNil[0];
        STAssertEqualObjects(newObj.objId, obj2.objId, @"Should get back the right id");
        ReffedTestClass* ref = newObj.thisOther;
        STAssertTrue([ref isKindOfClass:[ReffedTestClass class]], @"Should be a ref class");
        STAssertEqualObjects(ref.objId, obj1.objId, @"should get back the right object");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        STAssertEquals((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        STAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        STAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete >= done, @"should be monotonically increasing");
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
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
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
        ReffedTestClass* prime1 = objectsOrNil[0];
        ReffedTestClass* prime2 = objectsOrNil[1];
        ReffedTestClass* prime3 = objectsOrNil[2];
        ReffedTestClass* prime4 = objectsOrNil[3];
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
    
    LinkedTestClass* obj3 = [[LinkedTestClass alloc] init];
    obj3.objCount = 3;
    obj3.objDescription = @"testNestedReferences : Bottom Object";
    obj2.other = obj3;
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NestingRefClass class]] options:nil];
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
        LinkedTestClass* bottomRef = newRef.other;
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

- (void) testQueryHasRef
{
    NestingRefClass* obj1 = [[NestingRefClass alloc] init];
    obj1.objCount = 1;
    obj1.objDescription = @"testNestedReferences : Top Object";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objCount = 2;
    obj2.objDescription = @"testNestedReferences : Middle Object";
    obj1.relatedObject = obj2;
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NestingRefClass class]] options:nil];
    [store saveObject:obj1 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = objectsOrNil[0];
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

    KCSQuery *query = [KCSQuery queryOnField:@"relatedObject._id" withExactMatchForValue:obj2];
    
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = objectsOrNil[0];
        ReffedTestClass* newRef = ret.relatedObject;
        STAssertEquals(newRef.objCount, obj2.objCount, @"Should be the same object back");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}
//TODO: note different objs
//TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''

- (void) testUserAssociation
{
    UserRefTestClass* obj = [[UserRefTestClass alloc] init];
    obj.objCount = -3000;
    obj.objDescription = @"auser that knows about another user";
    obj.auser = [KCSUser activeUser];
    
    STAssertNotNil(obj.auser, @"should have a nonnull user");
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[UserRefTestClass class]] options:nil];
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        UserRefTestClass* ret = [objectsOrNil objectAtIndex:0];
        KCSUser* retUser = ret.auser;
        STAssertTrue([retUser isKindOfClass:[KCSUser class]], @"should be a user");
        STAssertEqualObjects([retUser username],[KCSUser activeUser].username, @"usernames should match");
        
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

#pragma mark graph

- (void) testThatNonRecursiveGeneratesError
{
    NoSaveTestClass* t = [[NoSaveTestClass alloc] init];
    t.objDescription = @"nnn";
    t.objCount = 10;
    
    ReffedTestClass* r = [[ReffedTestClass alloc] init];
    r.objDescription = @"r";
    r.objCount = 700;
    t.relatedObject = r;
    
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NoSaveTestClass class]] options:nil];
    [store saveObject:t withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertObjects(0);
        STAssertNotNil(errorOrNil, @"should have an error");
        STAssertEquals((int)errorOrNil.code, (int)KCSReferenceNoIdSetError, @"expecting no id error");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testThatNonRecursiveGoodWithIdDoesNotSave
{
    NoSaveTestClass* t = [[NoSaveTestClass alloc] init];
    t.objDescription = @"nnn";
    t.objCount = 10;
    
    ReffedTestClass* r1 = [[ReffedTestClass alloc] init];
    r1.objDescription = @"r";
    r1.objCount = 710;
    r1.objId = @"testThatNonRecursiveGoodWithIdDoesNotSave";
    t.relatedObject = r1;
    
    
    //--- presave an object with a different count but same id as our reference. The test for not save will make sure that the ref object does not
    //revert to the known object in the backend
    ReffedTestClass* r2 = [[ReffedTestClass alloc] init];
    r2.objDescription = @"r";
    r2.objCount = 9000;
    r2.objId = @"testThatNonRecursiveGoodWithIdDoesNotSave";

    NSString* refClass = @"NestedOtherCollection";
    KCSCollection* refCollection = [KCSCollection collectionFromString:refClass ofClass:[ReffedTestClass class]];
    KCSLinkedAppdataStore* refStore = [KCSLinkedAppdataStore storeWithCollection:refCollection options:nil];
    self.done = NO;
    [refStore saveObject:r2 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    
    
    //now test the save doesn't error but also doesn't save
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NoSaveTestClass class]] options:nil];
    [store saveObject:t withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        NoSaveTestClass* tb = objectsOrNil[0];
        ReffedTestClass* rb = tb.relatedObject;
        STAssertNotNil(rb, @"good object");
        STAssertEquals((int)rb.objCount, (int)710, @"should match orig value, not saved");
        
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testBrokenReference
{
    LinkedTestClass* ref = TestClass(0);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.other = ref;
    
    self.done = NO;
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
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
    
    KCSAppdataStore* otherStore = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:@"OtherCollection" ofClass:[LinkedTestClass class]] options:nil];
    [otherStore removeObject:ref withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    
    self.done = NO;
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
        STAssertNil(newRef, @"should be nil");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        STAssertTrue(percentComplete > done, @"should be monotonically increasing");
        STAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        done = percentComplete;
    }];
    [self poll];
}

- (void) testBrokenFile
{
    LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.resource = [self makeImage];
    
    self.done = NO;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* obj = objectsOrNil[0];
        STAssertNotNil(obj, @"should not be nil obj");
        STAssertNotNil(obj.resource, @"should still have an image");
        STAssertTrue([obj.resource isKindOfClass:[UIImage class]], @"Should still be an image");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    __block NSString* imageId = nil;
    KCSAppdataStore* noRefStore = [KCSAppdataStore storeWithCollection:_collection options:nil];
    [noRefStore loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        LinkedTestClass* foo = objectsOrNil[0];
        NSDictionary* resourceDict = foo.resource;
        imageId = resourceDict[@"_id"];
        self.done = YES;
    } withProgressBlock: nil];
    [self poll];

    STAssertNotNil(imageId, @"Should have an image id");
    
    self.done = NO;
    [KCSFileStore deleteFile:imageId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 1, @"Should be one deletion");
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"should be an error");
        KTAssertEqualsInt(errorOrNil.code, 404, @"file not found");
        STAssertEqualObjects(errorOrNil.domain, KCSFileStoreErrorDomain, @"should be a file error");
        STAssertObjects(1);
        LinkedTestClass* o = objectsOrNil[0];
        STAssertNil(o.resource, @"should be nilled");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

@end
