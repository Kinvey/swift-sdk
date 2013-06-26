//
//  KinveyKitEntityTests.m
//  KinveyKit
//
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KinveyKitEntityTests.h"
#import "TestUtils.h"

#import "KinveyEntity.h"

#import "KCSObjectMapper.h"

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "CLLocation+Kinvey.h"
#import "KinveyErrorCodes.h"
#import "KCSLogManager.h"
#import "KCSFile.h"
#import "KCSFileStore.h"

@interface TestObject : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *testId;
@property (nonatomic, retain) NSString *testParam1;
@property (nonatomic, retain) NSNumber *testParam2;
@property (nonatomic, retain) NSDate* dateParam;
@property (nonatomic, retain) NSSet* setParam;
@property (nonatomic, retain) NSOrderedSet* oSetParam;
@property (nonatomic, retain) NSMutableAttributedString* asParam;
@property (nonatomic, retain) CLLocation* locParam;
@property (nonatomic, retain) UIImage* image;
@end

@implementation TestObject

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"testId" : KCSEntityKeyId,
             @"testParam1" : @"testParam1i",
             @"testParam2" : @"testParam2i",
             @"setParam"   : @"setParam",
             @"dateParam" : @"dateParam",
             @"oSetParam" : @"oSetParam",
             @"asParam" : @"asParam",
             @"locParam" : @"locParam",
             @"image" : @"image"};
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"image" : KCSFileStoreCollectionName};
}
@end

@interface BrokenHostMappingObj : NSObject <KCSPersistable>

@end

@implementation BrokenHostMappingObj
- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary* mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = @{@"objectId" : KCSEntityKeyId};
                    });
        return mapping;
}

@end

@implementation KinveyKitEntityTests

- (void) testTypesSerialize
{
    TestObject* t = [[TestObject alloc] init];
    t.testId = @"idX";
    t.testParam1 = @"p1";
    t.testParam2 = @1.245;
    t.dateParam = [NSDate dateWithTimeIntervalSince1970:0];
    t.setParam = [NSSet setWithArray:@[@"2",@"1",@7]];
    t.oSetParam = [NSOrderedSet orderedSetWithArray:@[@"2",@"1",@7]];
    NSMutableAttributedString* s  = [[NSMutableAttributedString alloc] initWithString:@"abcdef"];
    [s setAttributes:@{@"myattr" : @"x"} range:NSMakeRange(1, 2)];
    t.asParam = s;
    t.locParam = [[CLLocation alloc] initWithLatitude:10 longitude:130];
    
    KCSSerializedObject* so = [KCSObjectMapper makeKinveyDictionaryFromObject:t error:NULL];
    STAssertNotNil(so, @"should not have a nil object");
    
    NSDictionary* d = [so dataToSerialize];
    STAssertNotNil(d, @"should not have a nil dictionary");
    STAssertEquals([d count], (NSUInteger) 8, @"should have 8 params");
    
    STAssertEqualObjects([d objectForKey:KCSEntityKeyId], @"idX", @"should have set the id");
    STAssertEqualObjects([d objectForKey:@"testParam1i"],  @"p1", @"should have set the string");
    STAssertEqualObjects([d objectForKey:@"testParam2i"],  @1.245, @"should have set the number");
    STAssertEqualObjects([d objectForKey:@"dateParam"],   @"ISODate(\"1970-01-01T00:00:00.000Z\")", @"should have set the date");
    NSArray* a = @[@"2",@"1",@7];
    STAssertEqualObjects([d objectForKey:@"setParam"],    a, @"should have set the set");
    STAssertEqualObjects([d objectForKey:@"oSetParam"],   a, @"should have set the ordered set");
    STAssertEqualObjects([d objectForKey:@"asParam"],   @"abcdef", @"should have set the ordered set");
    a = @[@130,@10];
    STAssertEqualObjects([d objectForKey:@"locParam"], a, @"should have set cllocation");
}

- (void) testTypesDeserialize
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30]};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    STAssertNotNil(out, @"Should not be nil");
    
    NSArray* a = @[@"2",@"1",@7];
    STAssertTrue([out.setParam isKindOfClass:[NSSet class]], @"should be a NSSet");
    STAssertEqualObjects(out.setParam,  [NSSet setWithArray:a], @"NSSets should be equal");
    STAssertTrue([out.oSetParam isKindOfClass:[NSOrderedSet class]], @"should be a NSOrderedSet");
    STAssertEqualObjects(out.oSetParam,  [NSOrderedSet orderedSetWithArray:a], @"NSOrderedSets should be equal");
    STAssertTrue([out.dateParam isKindOfClass:[NSDate class]], @"should be a NSOrderedSet");
    STAssertEqualObjects(out.dateParam,  [NSDate dateWithTimeIntervalSince1970:0], @"NSOrderedSets should be equal");
    STAssertTrue([out.asParam isKindOfClass:[NSMutableAttributedString class]], @"should be a NSOrderedSet");
    a = @[@100,@-30];
    STAssertEqualObjects([out.locParam kinveyValue] , a, @"should be matching CLLocation");
}

- (void) testLinkedRefOldStyle
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30],
                            @"image"       : @{
                                @"_loc" : @"OfflineSave-linked1-photo.png",
                                @"_mime-type" : @"image/png",
                                @"_type" : @"resource"
                            }};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    STAssertNotNil(out, @"Should not be nil");
    id im = out.image;
    STAssertNotNil(im, @"image should be valid");
    STAssertTrue([im isKindOfClass:[NSDictionary class]], @"should be a dictionary");
    
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    TestObject* out2 = [KCSObjectMapper makeObjectWithResourcesOfType:[TestObject class] withData:data withResourceDictionary:resources];

    STAssertNotNil(out2, @"Should not be nil");
    id im2 = out2.image;
    STAssertNil(im2, @"image should be nil");
    STAssertEquals((int) 1, (int) resources.count, @"should have a resource to load");

    KCSFile* imgRef = resources[@"image"];
    STAssertNotNil(imgRef, @"should have an image value");
    STAssertEqualObjects(imgRef.filename, @"OfflineSave-linked1-photo.png", @"ids should match");
}

- (void) testLinkedFile
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30],
                            @"image"       : @{
                                    @"_downloadURL" : @"http://images.com/OfflineSave-linked1-photo.png",
                                    @"_mimeType" : @"image/png",
                                    @"_id" : @"special-image-id",
                                    @"_type" : @"KinveyFile"
                                    }};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    STAssertNotNil(out, @"Should not be nil");
    id im = out.image;
    STAssertNotNil(im, @"image should be valid");
    STAssertTrue([im isKindOfClass:[NSDictionary class]], @"should be a dictionary");
    
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    TestObject* out2 = [KCSObjectMapper makeObjectWithResourcesOfType:[TestObject class] withData:data withResourceDictionary:resources];
    
    STAssertNotNil(out2, @"Should not be nil");
    id im2 = out2.image;
    STAssertNil(im2, @"image should be nil");
    STAssertEquals((int) 1, (int) resources.count, @"should have a resource to load");
    
    KCSFile* imgRef = resources[@"image"];
    STAssertNotNil(imgRef, @"should have an image value");
    STAssertEqualObjects(imgRef.fileId, @"special-image-id", @"ids should match");
    STAssertEqualObjects(imgRef.remoteURL, [NSURL URLWithString:@"http://images.com/OfflineSave-linked1-photo.png"], @"urls should match");
}

- (void) testBrokenPropMap
{
    [KCSLogManager sharedLogManager].suppressErrorToExceptionOnTest = YES;
    
    BrokenHostMappingObj* obj = [[BrokenHostMappingObj alloc] init];
    NSError* error = nil;
    KCSSerializedObject* d = [KCSObjectMapper makeKinveyDictionaryFromObject:obj error:&error];
    STAssertNil(d, @"should be nil");
    STAssertNotNil(error, @"Should have an error");
    STAssertEquals((int)KCSInvalidKCSPersistableError, (int) error.code, @"should make a invalid persistable error");

    [KCSLogManager sharedLogManager].suppressErrorToExceptionOnTest = NO;
}

- (void) testPopulateExistingDoesntKillResources
{
    TestObject* obj = [[TestObject alloc] init];
    obj.image = [UIImage new];
    obj.testId = @"12345";
    
    NSDictionary* newData = @{KCSEntityKeyId : obj.testId, @"image" : @{@"_type":@"KinveyFile", @"_id":@"TestObjects-12345-image"}};
    
    NSError* error = nil;
    KCSSerializedObject* o = [KCSObjectMapper makeResourceEntityDictionaryFromObject:obj forCollection:@"TestObjects" error:&error];
    STAssertNil(error, @"should serialize correctly");
    STAssertNotNil(o.resourcesToSave, @"Should have resources");
    KTAssertCount(1, o.resourcesToSave);
    
    [KCSObjectMapper populateExistingObject:o withNewData:newData];
    
    STAssertNotNil(obj.testId, @"should not nil id");
    UIImage* resolvedImage = obj.image;
    STAssertNotNil(resolvedImage, @"should still be an image");
    STAssertTrue([resolvedImage isKindOfClass:[UIImage class]], @"still an image");
}
@end
