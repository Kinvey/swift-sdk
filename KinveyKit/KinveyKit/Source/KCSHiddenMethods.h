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

@interface KCSQueryTTLModifier : NSObject
@property (nonatomic, strong) NSNumber* ttl;
- (instancetype) initWithTTL:(NSNumber*)ttl;
@end
@interface KCSQuery (KCSHiddenMethods)
@property (nonatomic, retain) NSArray* referenceFieldsToResolve;
@property (nonatomic, readwrite, copy) NSMutableDictionary *query;
@property (nonatomic, strong) KCSQueryTTLModifier* ttlModifier;
@end



@interface KCSCollection (KCSHiddenMethods)

- (KCSRESTRequest*)restRequestForMethod:(KCSRESTMethod)method apiEndpoint:(NSString*)endpoint;
- (NSString*) urlForEndpoint:(NSString*)endpoint;

@end

@interface KCSClient (KCSHiddenMethods)
@property (nonatomic, copy, readonly) NSString *rpcBaseURL;
@property (nonatomic, strong) NSString* kinveyDomain;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString* port;

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
- (instancetype) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)pACL;
@end

@interface KCSFileStore (KCSHiddenMethods)
+ (void) uploadKCSFile:(KCSFile*)file options:(NSDictionary*)options completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;
+ (void)downloadKCSFile:(KCSFile*) file completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock) progressBlock;

+ (id) lastRequest;
@end


#define KCSFileStoreTestExpries @"KCSFileStore.Test.Expires"
@interface KCSFile (KCSHiddenMethods)
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, copy) NSString* gcsULID;
- (void) updateAfterUpload:(KCSFile*)newFile;
@end

#endif
