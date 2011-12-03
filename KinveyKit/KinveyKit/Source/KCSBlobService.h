//
//  KCSBlobService.h
//  SampleApp
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSClient;

@interface KCSBlobResponse : NSObject

@property (copy) NSString *localFileName;
@property (copy) NSString *blobId;
@property (retain) NSData *blob;
@property NSInteger length;

+ (KCSBlobResponse *)responseWithFileName: (NSString *)localFile withBlobId: (NSString *)blobId withData: (NSData *)blob withLength: (NSInteger)length;

@end

@protocol KCSBlobDelegate <NSObject>

- (void)blobRequestDidComplete: (KCSBlobResponse *)result;
- (void)blobRequestDidFail: (id)error;

@end

@interface KCSBlobService : NSObject

+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId;
+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId toFile: (NSString *)file;

+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file;
+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file toBlob: (NSString *)blobId;
+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveData:(NSData *) data toBlob: (NSString *)blobId;

+ (void)blobDelegate:(id<KCSBlobDelegate>)delegate deleteBlob:(NSString *)blobId;


@end
