//
//  KCSHiddenMethods.h
//  KinveyKit
//
//  Created by Michael Katz on 7/13/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KCSHiddenMethods_h
#define KinveyKit_KCSHiddenMethods_h

#import "KCSAppdataStore.h"
#import "KinveyCollection.h"
#import "KCSRESTRequest.h"

@interface KCSGenericRESTRequest (KCSHiddenMethods)
+ (NSString *)getHTTPMethodForConstant:(NSInteger)constant;
@end

@interface KCSQuery (KCSHiddenMethods)
@property (nonatomic, retain) NSArray* referenceFieldsToResolve;

@end

@interface KCSCollection (KCSHiddenMethods)

- (KCSRESTRequest*)restRequestForMethod:(KCSRESTMethod)method apiEndpoint:(NSString*)endpoint;

@end

@interface KCSAppdataStore (KCSHiddenMethods)
- (BOOL) isKinveyReachable;
- (NSUInteger) numberOfPendingSaves;
#if BUILD_FOR_UNIT_TEST
- (void) setReachable:(BOOL)reachOverwrite;
#endif
@end

#endif
