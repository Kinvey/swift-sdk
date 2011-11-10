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

@property (retain) NSString *localFileName;
@property (retain) NSString *blobId;
@property (retain) NSData *blob;
@property NSInteger length;

@end

@protocol KCSBlobDelegate <NSObject>

- (void)blobRequestDidComplete: (KCSBlobResponse *)result;
- (void)blobRequestDidFail: (id)error;

@end

@interface KCSBlobService : NSObject

@property (retain) KCSClient *kinveyClient;

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId;
- (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId toFile: (NSString *)file;

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file;
- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file toBlob: (NSString *)blobId;
- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveData:(NSData *) toBlob: (NSString *)blobId;

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate deleteBlog:(NSString *)blobId;


@end
