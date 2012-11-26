//
//  KCSErrorUtilities.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSErrorUtilities : NSObject
//TODO: cleanup
+ (NSDictionary *)createErrorUserDictionaryWithDescription: (NSString *)description
                                         withFailureReason: (NSString *)reason
                                    withRecoverySuggestion: (NSString *)suggestion
                                       withRecoveryOptions: (NSArray *)options;

+ (NSError*) createError:(NSDictionary*)jsonErrorDictionary description:(NSString*) description errorCode:(NSInteger)errorCode domain:(NSString*)domain requestId:(NSString*)requestId sourceError:(NSError*)underlyingError;

+ (NSError*) createError:(NSDictionary*)jsonErrorDictionary description:(NSString*) description errorCode:(NSInteger)errorCode domain:(NSString*)domain requestId:(NSString*)requestId;

@end
