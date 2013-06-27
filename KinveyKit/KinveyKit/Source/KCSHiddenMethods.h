//
//  KCSHiddenMethods.h
//  KinveyKit
//
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KCSHiddenMethods_h
#define KinveyKit_KCSHiddenMethods_h

#import "KCSAppdataStore.h"
#import "KinveyCollection.h"
#import "KCSRESTRequest.h"
#import "KCSClient.h"
#import "KCSReduceFunction.h"
#import "KCSGroup.h"
#import "KinveyUser.h"
#import "KCSMetadata.h"
#import "KCSFileStore.h"
#import "KCSFile.h"

NSDictionary* defaultBuilders();

@interface KCSGenericRESTRequest (KCSHiddenMethods)
+ (NSString *)getHTTPMethodForConstant:(NSInteger)constant;
@end

@interface KCSQuery (KCSHiddenMethods)
@property (nonatomic, retain) NSArray* referenceFieldsToResolve;
@property (nonatomic, readwrite, copy) NSMutableDictionary *query;
@end

@interface KCSCollection (KCSHiddenMethods)

- (KCSRESTRequest*)restRequestForMethod:(KCSRESTMethod)method apiEndpoint:(NSString*)endpoint;
- (NSString*) urlForEndpoint:(NSString*)endpoint;

@end

@interface KCSClient (KCSHiddenMethods)
@property (nonatomic, copy, readonly) NSString *rpcBaseURL;
@end


@interface KCSReduceFunction (KCSHiddenMethods)
@property (nonatomic, readonly) BOOL buildsObjects;
@end


@interface KCSGroup (KCSHiddenMethods)
- (NSDictionary*) dictionaryValue;
@end


@interface KCSUser (KCSHiddenMethods)
+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock forceNew:(BOOL)forceNew;
@end

@interface KCSMetadata (KCSHiddenMethods)
- (NSDictionary*) aclValue;
@end

@interface KCSFileStore (KCSHiddenMethods)
+ (void) uploadKCSFile:(KCSFile*)file completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;
+ (void)downloadKCSFile:(KCSFile*) file completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock) progressBlock;

+ (id) lastRequest;
@end

@interface KCSFile (KCSHiddenMethods)
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic, retain) NSData* data;
- (void) updateAfterUpload:(KCSFile*)newFile;
@end

#endif
