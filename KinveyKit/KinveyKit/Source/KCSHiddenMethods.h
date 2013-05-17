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

@interface KCSAppdataStore (KCSHiddenMethods)
- (BOOL) isKinveyReachable;
- (NSUInteger) numberOfPendingSaves;
#if BUILD_FOR_UNIT_TEST
- (void) setReachable:(BOOL)reachOverwrite;
#endif
@end

@interface KCSReduceFunction (KCSHiddenMethods)
@property (nonatomic, readonly) BOOL buildsObjects;
@end


@interface KCSGroup (KCSHiddenMethods)
- (NSDictionary*) dictionaryValue;
@end
#endif
