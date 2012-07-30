//
//  KCSErrorUtilities.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"

#define KCS_ERROR_DEBUG_KEY @"debug"
#define KCS_ERROR_DESCRIPTION_KEY @"description"
#define KCS_ERROR_KINVEY_ERROR_CODE_KEY @"error"

@implementation KCSErrorUtilities

//NSLocalizedDescriptionKey
//NSLocalizedFailureReasonErrorKey
//NSLocalizedRecoverySuggestionErrorKey
//NSLocalizedRecoveryOptionsErrorKey

+ (NSDictionary *)createErrorUserDictionaryWithDescription:(NSString *)description
                                         withFailureReason:(NSString *)reason
                                    withRecoverySuggestion:(NSString *)suggestion 
                                       withRecoveryOptions:(NSArray *)options
{
    if (description == nil || reason == nil || suggestion == nil){
        // This is an error!!!
        return nil;
    }
    
    NSMutableArray *localizedOptions = [NSMutableArray array];
    for (NSString *option in options) {
        [localizedOptions addObject:NSLocalizedString(option, nil)];
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSArray arrayWithArray:localizedOptions], NSLocalizedRecoveryOptionsErrorKey,
                              NSLocalizedString(description, nil), NSLocalizedDescriptionKey,
                              NSLocalizedString(reason, nil), NSLocalizedFailureReasonErrorKey,
                              NSLocalizedString(suggestion, nil), NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    
    return userInfo;
}

+ (NSError*) createError:(NSDictionary*)jsonErrorDictionary description:(NSString*) description errorCode:(NSInteger)errorCode domain:(NSString*)domain
{
    NSDictionary* userInfo = [NSMutableDictionary dictionary];
    description = (description == nil) ? [jsonErrorDictionary objectForKey:KCS_ERROR_DESCRIPTION_KEY] : description;
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[jsonErrorDictionary objectForKey:KCS_ERROR_KINVEY_ERROR_CODE_KEY] forKey:KCSErrorCode];
    [userInfo setValue:[jsonErrorDictionary objectForKey:KCS_ERROR_DEBUG_KEY] forKey:KCSErrorInternalError];
    [userInfo setValue:@"Retry request based on information in JSON Error" forKey:NSLocalizedRecoverySuggestionErrorKey];
    [userInfo setValue:[NSString stringWithFormat:@"JSON Error: %@", [jsonErrorDictionary objectForKey:KCS_ERROR_DESCRIPTION_KEY]] forKey:NSLocalizedFailureReasonErrorKey];
    
    
    NSError *error = [NSError errorWithDomain:domain code:errorCode userInfo:userInfo];
    return error;
}

@end
