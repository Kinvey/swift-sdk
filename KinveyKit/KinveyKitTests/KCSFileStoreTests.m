//
//  KCSFileStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 6/18/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TestUtils.h"

#import "KCSFile.h"
#import "KCSFileStore.h"
#import "NSArray+KinveyAdditions.h"

#define KTAssertIncresing(var) \
{ \
    KTAssertCountAtLeast(1, var); \
    NSMutableArray* lastdouble = [NSMutableArray arrayWith:var.count copiesOf:@(-1)]; \
    for (id v in var) { \
        NSArray* vArr = [NSArray wrapIfNotArray:v]; \
        [vArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) { \
                double thisdouble = [obj doubleValue]; \
                XCTAssertTrue(thisdouble >= [lastdouble[idx] doubleValue], @"should be increasing value"); \
                lastdouble[idx] = @(thisdouble); \
            }];\
}}


#define SETUP_PROGRESS \
    NSMutableArray* progresses = [NSMutableArray array]; \
    NSMutableArray* datas = [NSMutableArray array];
#define PROGRESS_BLOCK \
    ^(NSArray *objects, double percentComplete) { \
        [progresses addObject:@(percentComplete)]; \
        [datas addObject:[objects valueForKeyPath:@"length"]]; \
    }
#define ASSERT_PROGESS \
    KTAssertIncresing(progresses); \
    KTAssertIncresing(datas);


#define kTestId @"testData"
#define kTestMimeType @"text/plain"
#define kTestFilename @"test.txt"

#define kImageFilename @"mavericks.jpg"
#define kImageMimeType @"image/jpeg"
#define kImageSize 3510397

@interface KCSFileStoreTests : SenTestCase

@end

@implementation KCSFileStoreTests

NSData* testData()
{
    NSString* loremIpsum = @"Et quidem saepe quaerimus verbum Latinum par Graeco et quod idem valeat; Non quam nostram quidem, inquit Pomponius iocans; Ex rebus enim timiditas, non ex vocabulis nascitur. Nunc vides, quid faciat. Tum Piso: Quoniam igitur aliquid omnes, quid Lucius noster? Graece donan, Latine voluptatem vocant. Mihi, inquam, qui te id ipsum rogavi? Quem Tiberina descensio festo illo die tanto gaudio affecit, quanto L. Primum in nostrane potestate est, quid meminerimus? Si quidem, inquit, tollerem, sed relinquo. Quo modo autem philosophus loquitur? Sic enim censent, oportunitatis esse beate vivere.";
    NSData* ipsumData = [loremIpsum dataUsingEncoding:NSUTF16BigEndianStringEncoding];
    return ipsumData;
}

- (NSURL*) largeImageURL
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:@"mavericks" withExtension:@"jpg"];
}

- (void) setUpTestFile
{
    KCSMetadata* metadata = [[KCSMetadata alloc] init];
    [metadata setGloballyWritable:YES];
    [metadata setGloballyReadable:YES];
    [KCSFileStore uploadData:testData() options:@{ KCSFileId : kTestId, KCSFileACL : metadata, KCSFileMimeType : kTestMimeType, KCSFileFileName : kTestFilename} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (NSURL*) getDownloadURLForId:(NSString*)fileId
{
    KCSAppdataStore* metaStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];

    self.done = NO;
    __block NSURL* downloadURL = nil;
    [metaStore loadObjectWithID:fileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertCount(1, objectsOrNil);
        KCSFile* downloadFile = objectsOrNil[0];
        downloadURL = downloadFile.remoteURL;
        STAssertNotNil(downloadURL, @"Should have a valid download URL");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    return downloadURL;
}

- (void)setUp
{
    [super setUp];
    
    XCTAssertTrue([TestUtils setUpKinveyUnittestBackend], @"Should be set up.");
    
    self.done = NO;
    [self setUpTestFile];
}

- (void)tearDown
{
    self.done = NO;
    [KCSFileStore deleteFile:kTestId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        if (errorOrNil != nil && errorOrNil.code == KCSNotFoundError) {
            //was hopefully removed by a test
        } else {
            STAssertNoError;
            STAssertEquals((unsigned long)1, count, @"should have deleted the temp data");
        }
        self.done = YES;
    }];
    [self poll];
    
    [super tearDown];
}

#pragma mark - Download Data

- (void)testDownloadBasic
{
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadData:kTestId completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        KCSFile* resource = downloadedResources[0];
        XCTAssertNil(resource.localURL, @"should have no local url for data");
        XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
        XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
        XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
        
        NSData* origData = testData();
        
        XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
        XCTAssertEquals(resource.length, origData.length, @"should have matching lengths");
        
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

//TODO: Test error conditions
//TODO: Test multiple ids
//TODO: test path components slashes, spaces, etc, dots
//TODO: test no mimeType
//TODO: test content type

- (void) testDownloadToFile
{
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        KCSFile* resource = downloadedResources[0];
        XCTAssertNil(resource.data, @"should have no local data");
        XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
        XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
        XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
        
        NSURL* localURL = resource.localURL;
        XCTAssertNotNil(localURL, @"should have a URL");
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
        XCTAssertTrue(exists, @"file should exist");
        
        error = nil;
        NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
        XCTAssertNil(error, @"%@",error);
        
        NSData* origData = testData();
        KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
        
        [[NSFileManager defaultManager] removeItemAtURL:resource.localURL error:&error];
        STAssertNoError_
        
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

- (void) testDownloadToFileOptionsFilename
{
    NSString* filename = @"hookemsnivy.rtf";
    
    self.done = NO;
    [KCSFileStore downloadFile:kTestId options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        
        NSURL* localURL = dlFile.localURL;
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertEqualObjects([localURL lastPathComponent], filename, @"local file should have the specified filename");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[localURL path]], @"should exist");
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
        STAssertNoError_;
        
        NSData* origData = testData();
        KTAssertEqualsInt([attributes[NSFileSize] intValue], origData.length, @"should have matching data");

        [[NSFileManager defaultManager] removeItemAtURL:localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

//TODO: test specifying location
//TODO: get by filename!

- (void) testGetByFileName
{
    self.done = NO;
    __block NSString* fileId;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        self.done = YES;
    } progressBlock:nil];
    [self poll];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadDataByName:kImageFilename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        KCSFile* resource = downloadedResources[0];
        XCTAssertNil(resource.localURL, @"should have no local url for data");
        XCTAssertNotNil(resource.data, @"Should have data");
        XCTAssertEqualObjects(resource.fileId, fileId, @"file ids should match");
        XCTAssertEqualObjects(resource.filename, kImageFilename, @"should have a filename");
        XCTAssertEqualObjects(resource.mimeType, kImageMimeType, @"should have a mime type");
        KTAssertEqualsInt(resource.length, kImageSize, @"should have matching lengths");
        KTAssertEqualsInt(resource.data.length, kImageSize, @"should have matching lengths");
        
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
    
    if (fileId) {
        self.done = NO;
        [KCSFileStore deleteFile:fileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            self.done = YES;
        }];
        [self poll];
    }
}


//TODO: query by filename

- (void) testGetFileIsNotThere
{
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFile:@"NOSUCHFILE" options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNotNil(error, @"should get an error");
        STAssertNil(downloadedResources, @"should get no resources");
        STAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);
}

#pragma mark - download from a resolved URL

- (void) testDownloadWithResolvedURL
{
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLOptionsFilename
{
    NSString* filename = @"hookemsnivy.rtf";
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, filename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLOptionsIfNewer
{
    //start by downloading file
    __block NSDate* firsDate = nil;
    self.done = NO;
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        firsDate = attributes[NSFileModificationDate];
        self.done = YES;
    } progressBlock:nil];
    [self poll];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        NSDate* thisDate = attributes[NSFileModificationDate];
        STAssertEqualObjects(thisDate, firsDate, @"file should not have been modified");
        
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    //should have no progress b/c they are local
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);
}


- (void) testDownloadWithResolvedURLOptionsIfNewerButNotNewer
{
    //start by downloading file
    
    __block NSDate* firstDate = nil;
    self.done = NO;
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        firstDate = attributes[NSFileModificationDate];
        self.done = YES;
    } progressBlock:nil];
    [self poll];
    
    
    [NSThread sleepForTimeInterval:0.5];
    
    //then re-upload file
    self.done = NO;
    [KCSFileStore uploadData:testData() options:@{KCSFileId : kTestId} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_
        self.done = YES;
    } progressBlock:nil];
    [self poll];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        NSDate* thisDate = attributes[NSFileModificationDate];
        STAssertTrue([firstDate compare:thisDate] == NSOrderedAscending, @"file should not have been modified");
        
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLOptionsFilenameAndNewer
{
    NSString* filename = @"hookemsnivy.rtf";
    
    //start by downloading file
    __block NSDate* firsDate = nil;
    self.done = NO;
    [KCSFileStore downloadFile:kTestId options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        firsDate = attributes[NSFileModificationDate];
        self.done = YES;
    } progressBlock:nil];
    [self poll];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileFileName : filename, KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, filename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, @"text/rtf", @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");

        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
        STAssertNoError_;
        NSDate* thisDate = attributes[NSFileModificationDate];
        STAssertEqualObjects(thisDate, firsDate, @"file should not have been modified");
        
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    //should have no progress b/c they are local
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);

}

- (void) testDownloadWithResolvedURLStopAndResume
{
    STFail(@"NIY");
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLStopAndResumeFromBeginningIfNewer
{
    STFail(@"NIY");
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    self.done = NO;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        KCSFile* dlFile = downloadedResources[0];
        STAssertNil(dlFile.data, @"no data");
        STAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
        STAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
        STAssertEquals(dlFile.length, testData().length, @"lengths should match");
        STAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
        STAssertNotNil(dlFile.localURL, @"should be a local URL");
        STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
        NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
        STAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
        [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
        STAssertNoError_
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
}

#pragma mark - Streaming

- (void) testStreamingBasic
{
    self.done = NO;
    [KCSFileStore getStreamingURL:kTestId completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_;
        XCTAssertNil(streamingResource.localURL, @"should have no local url for data");
        XCTAssertEqualObjects(streamingResource.fileId, kTestId, @"file ids should match");
        XCTAssertEqualObjects(streamingResource.filename, kTestFilename, @"should have a filename");
        XCTAssertEqualObjects(streamingResource.mimeType, kTestMimeType, @"should have a mime type");
        XCTAssertNil(streamingResource.data, @"should have no data");
        XCTAssertNil(streamingResource.data, @"should have no data");
        XCTAssertEquals(streamingResource.length, testData().length, @"should have matching lengths");
        XCTAssertNotNil(streamingResource.remoteURL, @"should have a remote URL");
        XCTAssertNotNil(streamingResource.expirationDate, @"should have a valid date");
        XCTAssertTrue([streamingResource.expirationDate isKindOfClass:[NSDate class]], @"should be a date");
        self.done = YES;
    }];
    [self poll];
}
//test error conditions
//test streaming by name
//to get uiimage with url

#pragma mark - Uploading

- (void) testSaveLocalResource
{
    self.done = NO;
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertEqualObjects(uploadInfo.filename, kImageFilename, @"filename should match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:kImageFilename], @"file id should be unique");
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        
        newFileId = uploadInfo.fileId;
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    [self poll];
    ASSERT_PROGESS
    
    if (newFileId) {
        self.done = NO;
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            self.done = YES;
        }];
        [self poll];
    }
}

- (void) testSaveDataBasic
{
    self.done = NO;
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        KTAssertEqualsInt(uploadInfo.length, testData().length, @"sizes should match");
        XCTAssertNil(uploadInfo.localURL, @"should be nil");
        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"should use default mimetype");
        
        newFileId = uploadInfo.fileId;
        self.done = YES;
    } progressBlock:PROGRESS_BLOCK];
    
    [self poll];
    ASSERT_PROGESS
    
    if (newFileId) {
        self.done = NO;
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            self.done = YES;
        }];
        [self poll];
    }
}

#pragma mark - Delete

- (void) testDelete
{
    self.done = NO;
    [KCSFileStore deleteFile:kTestId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 1, @"should have deleted one file");
        self.done = YES;
    }];
    [self poll];
    
    self.done = NO;
    [KCSFileStore downloadData:kTestId completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNotNil(error, @"should get an error");
        STAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

@end
