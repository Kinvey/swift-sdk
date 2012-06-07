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

@implementation KCSLinkedAppdataStoreTests


- (void) setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(loaded, @"should be loaded");
    
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = @"testObjects";
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
        STAssertNil(errorOrNil, @"should not be any errors");
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
        STAssertNil(errorOrNil, @"should not be any errors");
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
        STAssertNil(errorOrNil, @"should not be any errors");
        STAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        obj = [objectsOrNil objectAtIndex:0];
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"should not be any errors");
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


@end
