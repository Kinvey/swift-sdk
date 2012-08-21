//
//  KCSResourceStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 6/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSResourceStoreTests.h"

#import <KinveyKit/KinveyKit.h>
#import "TestUtils.h"

@interface UIColor (KinveyTests)
+ (UIColor*) randomColor;
@end

@implementation UIColor (KinveyTests)

+ (UIColor*) randomColor 
{
    CGFloat red    = rand() / (float) RAND_MAX;
    CGFloat green  = rand() / (float) RAND_MAX;
    CGFloat blue   = rand() / (float) RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.];
}

@end

@implementation KCSResourceStoreTests


- (void) setUp
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"Backend should be active");
}


- (UIImage*) makeImage
{
    UIGraphicsBeginImageContext(CGSizeMake(1000, 1000));
    CGFloat size = rand() / (float) RAND_MAX * 900.;
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(50, 50, size, size)];
    [[UIColor randomColor] setFill];
    [path fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


- (void) testOne
{
    UIImage* image = [self makeImage];
    
    NSData* data = UIImagePNGRepresentation(image);
    
    NSURL* fileUrl = [TestUtils randomFileUrl:@"png"];
    
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:[fileUrl URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    
    BOOL write = [data writeToURL:fileUrl atomically:YES];
    STAssertTrue(write, @"should have write the file");
    
    KCSResourceStore* store = [KCSResourceStore store];
    
    
    self.done = NO;
    [store saveObject:fileUrl withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
    }];    
    [self poll];
    
    NSString* fileName = [fileUrl lastPathComponent];
    
    self.done = NO;
    [store queryWithQuery:fileName withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        NSData* responseData = (NSData*)[(KCSResourceResponse*)[objectsOrNil objectAtIndex:0] resource];
        STAssertEqualObjects(responseData, data, @"Data should match");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
    }];
    [self poll];
    
    self.done = NO;
    [store removeObject:fileName withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
    }];    
    [self poll];
    
    self.done = NO;
    [store queryWithQuery:fileName withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"should be no errors");
        STAssertEquals([errorOrNil code], KCSNotFoundError, @"should be not found");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
    }];
    [self poll];
}

- (void) testError
{
    KCSResourceStore* store = [KCSResourceStore store];
    
    
    self.done = NO;
    [store queryWithQuery:@"nonexstent" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"should have an error");
        STAssertEqualObjects(@"BlobNotFound", [[errorOrNil userInfo] valueForKey:KCSErrorCode], @"error should be Blob Not Found");
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"-- %f",percentComplete);
    }];    
    [self poll];
}

@end
