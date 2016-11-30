//
//  KCSBooleanTestCase.m
//  KinveyKit
//
//  Created by Victor Hugo on 2016-11-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KCSTestCase.h"
#import <KinveyKit/KinveyKit.h>

@interface KCSBooleanTestCase_Profile : NSObject <KCSPersistable>

@property (nonatomic, copy) NSString* profileId;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, strong) NSMutableArray* nested;
@property (nonatomic, assign) char charValue;
@property (nonatomic, assign) int intValue;
@property (nonatomic, assign) short shortValue;
@property (nonatomic, assign) long longValue;
@property (nonatomic, assign) long long longLongValue;
@property (nonatomic, assign) unsigned char unsignedCharValue;
@property (nonatomic, assign) unsigned int unsignedIntValue;
@property (nonatomic, assign) unsigned short unsignedShortValue;
@property (nonatomic, assign) unsigned long unsignedLongValue;
@property (nonatomic, assign) unsigned long long unsignedLongLongValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, assign) _Bool boolC99Value;
@property (nonatomic, assign) bool boolCPPValue;

@end

@implementation KCSBooleanTestCase_Profile

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{
        @"profileId" : KCSEntityKeyId,
        @"title" : @"title",
        @"nested" : @"nested",
        @"charValue" : @"charValue",
        @"intValue" : @"intValue",
        @"shortValue" : @"shortValue",
        @"longValue" : @"longValue",
        @"longLongValue" : @"longLongValue",
        @"unsignedCharValue" : @"unsignedCharValue",
        @"unsignedIntValue" : @"unsignedIntValue",
        @"unsignedShortValue" : @"unsignedShortValue",
        @"unsignedLongValue" : @"unsignedLongValue",
        @"unsignedLongLongValue" : @"unsignedLongLongValue",
        @"floatValue" : @"floatValue",
        @"doubleValue" : @"doubleValue",
        @"boolValue" : @"boolValue",
        @"boolC99Value" : @"boolC99Value",
        @"boolCPPValue" : @"boolCPPValue"
    };
}

@end

@interface KCSBooleanTestCase_MockURLProtocol : NSURLProtocol

@end

@implementation KCSBooleanTestCase_MockURLProtocol

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return YES;
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

-(void)startLoading
{
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"1.1"
                                                            headerFields:@{ @"Content-Type" : @"application/json; charset=utf-8" }];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    NSDictionary* responseBody = @{
        @"_id" : @"object-id",
        @"title" : @"My Title",
        @"nested" : @[
            @{
                @"title" : @"My Nested Title",
                @"url" : @"http://test.kinvey.com/my-data",
                @"up" : @{
                    @"enabled" : @YES
                },
                @"down": @{
                    @"enabled" : @NO
                }
            }
        ],
        @"charValue" : [NSNull null],
        @"intValue" : [NSNull null],
        @"shortValue" : [NSNull null],
        @"longValue" : [NSNull null],
        @"longLongValue" : [NSNull null],
        @"unsignedCharValue" : [NSNull null],
        @"unsignedIntValue" : [NSNull null],
        @"unsignedShortValue" : [NSNull null],
        @"unsignedLongValue" : [NSNull null],
        @"unsignedLongLongValue" : [NSNull null],
        @"floatValue" : [NSNull null],
        @"doubleValue" : [NSNull null],
        @"boolValue" : [NSNull null],
        @"boolC99Value" : [NSNull null],
        @"boolCPPValue" : [NSNull null]
    };
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:responseBody
                                                   options:0
                                                     error:&error];
    if (error) @throw error;
    [self.client URLProtocol:self
                 didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

-(void)stopLoading
{
}

@end

@interface KCSBooleanTestCase : KCSTestCase

@end

@implementation KCSBooleanTestCase

- (void)setUp
{
    [super setUp];
    
    [self setupClient];
    [self createUser];
}

- (void)testBooleanValues
{
    [KCSURLProtocol registerClass:[KCSBooleanTestCase_MockURLProtocol class]];
    
    @try {
        XCTestExpectation* expectationLoad = [self expectationWithDescription:@"Load"];
        
        KCSCollection* collection = [KCSCollection collectionFromString:@"Profile"
                                                                ofClass:[KCSBooleanTestCase_Profile class]];
        KCSLinkedAppdataStore* dataStore = [KCSLinkedAppdataStore storeWithCollection:collection
                                                                              options:nil];
        [dataStore loadObjectWithID:@"object-id"
                withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
        {
            XCTAssertNotNil(objectsOrNil);
            XCTAssertNil(errorOrNil);
            
            if (objectsOrNil) {
                KCSBooleanTestCase_Profile* profile = objectsOrNil.firstObject;
                XCTAssertEqual(profile.charValue, '\0');
                XCTAssertEqual(profile.intValue, (int) 0);
                XCTAssertEqual(profile.shortValue, (short) 0);
                XCTAssertEqual(profile.longValue, (long) 0);
                XCTAssertEqual(profile.longLongValue, (long long) 0);
                XCTAssertEqual(profile.unsignedCharValue, (unsigned char) 0);
                XCTAssertEqual(profile.unsignedIntValue, (unsigned int) 0);
                XCTAssertEqual(profile.unsignedShortValue, (unsigned short) 0);
                XCTAssertEqual(profile.unsignedLongValue, (unsigned long) 0);
                XCTAssertEqual(profile.unsignedLongLongValue, (unsigned long long) 0);
                XCTAssertEqual(profile.floatValue, (float) 0);
                XCTAssertEqual(profile.doubleValue, (double) 0);
                XCTAssertEqual(profile.boolValue, (BOOL) NO);
                XCTAssertEqual(profile.boolC99Value, (_Bool) false);
                XCTAssertEqual(profile.boolCPPValue, (bool) false);
                if (profile && [profile isKindOfClass:[KCSBooleanTestCase_Profile class]]) {
                    for (NSMutableDictionary* nested in profile.nested) {
                        XCTAssertEqualObjects(nested[@"up"][@"enabled"], @YES);
                        XCTAssertEqualObjects(nested[@"down"][@"enabled"], @NO);
                    }
                }
            }
            
            [expectationLoad fulfill];
        } withProgressBlock:nil];
        
        [self waitForExpectationsWithTimeout:30 handler:nil];
        
        XCTAssertNotNil([KCSUser activeUser]);
    } @finally {
        [KCSURLProtocol unregisterClass:[KCSBooleanTestCase_MockURLProtocol class]];
    }
}

@end
