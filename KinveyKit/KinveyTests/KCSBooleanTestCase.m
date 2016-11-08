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

@end

@implementation KCSBooleanTestCase_Profile

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{
        @"profileId" : KCSEntityKeyId,
        @"title" : @"title",
        @"nested" : @"nested"
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
        ]
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
