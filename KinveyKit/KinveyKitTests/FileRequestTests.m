//
//  FileRequestTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/24/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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

#import <SenTestingKit/SenTestingKit.h>

#import "KinveyCoreInternal.h"
#import "KinveyFileStoreInteral.h"

#import "TestUtils2.h"

#define publicFileURL @"http://storage.googleapis.com/kinvey_staging_4b4b2dd210ba4b7d8b7ae5342176b137/67a183fc-b08d-4af6-a6ed-69fd688ce920/mavericks.jpg"
#define kImageSize 3510397

/* Test File loading irrespective of KCS blob service */
@interface FileRequestTests : SenTestCase

@end

@implementation FileRequestTests

- (void)setUp
{
    [super setUp];
    [self setupKCS];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testExample
{
    KCSFileRequest* f = [[KCSFileRequest alloc] init];
    KCSFile* file = [[KCSFile alloc] init];
    NSString* fileStr = @"/tmp/123.jpg";
    file.localURL = [NSURL URLWithString:fileStr];
    [[NSFileManager defaultManager] removeItemAtURL:file.localURL error:NULL];
    
    [f downloadStream:file
              fromURL:[NSURL URLWithString:publicFileURL]
  alreadyWrittenBytes:@0 completionBlock:^(BOOL done, NSDictionary *returnInfo, NSError *error) {
      KTAssertNoError
      long bytes = [returnInfo[@"bytesWritten"] longValue];
      NSDictionary* d = [[NSFileManager defaultManager] attributesOfItemAtPath:fileStr error:NULL];
      NSNumber* fileOnDiskSize = d[NSFileSize];
      STAssertEquals(bytes, (long)kImageSize, @"bytes downloaded should match");
      STAssertEquals(bytes, [fileOnDiskSize longValue], @"bytes should also match");
      KTPollDone
  } progressBlock:^(NSArray *objects, double percentComplete, NSDictionary *additionalContext) {
      
  }];
    KTPollStart
}

@end
