//
//  KCSErrorUtilities.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/10/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "NSMutableDictionary+KinveyAdditions.h"

#define KCS_ERROR_DEBUG_KEY @"debug"
#define KCS_ERROR_DESCRIPTION_KEY @"description"
#define KCS_ERROR_KINVEY_ERROR_CODE_KEY @"error"

#define kDatalinkError @"DLCError"

@implementation KCSErrorUtilities

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
    
    return @{
    NSLocalizedRecoveryOptionsErrorKey : [NSArray arrayWithArray:localizedOptions],
    NSLocalizedDescriptionKey : description,
    NSLocalizedFailureReasonErrorKey : reason,
    NSLocalizedRecoverySuggestionErrorKey : suggestion};
}

+ (NSError*) createError:(NSDictionary*)jsonErrorDictionary
             description:(NSString*) description
               errorCode:(NSInteger)errorCode
                  domain:(NSString*)domain
               requestId:(NSString*)requestId
             sourceError:(NSError*)underlyingError
{
    NSString* kcsErrorDescription = nil;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    
    if ([jsonErrorDictionary isKindOfClass:[NSDictionary class]] == NO) {
        kcsErrorDescription = (id) jsonErrorDictionary;
    } else {
        NSDictionary* ed = jsonErrorDictionary[@"error"];
        if (ed == nil || [ed isKindOfClass:[NSDictionary class]] == NO) {
            ed = jsonErrorDictionary;
        }
        NSMutableDictionary* errorValues = [ed mutableCopy];
        
        if ([errorValues isKindOfClass:[NSDictionary class]]) {
            NSString* kcsError = [errorValues popObjectForKey:KCS_ERROR_DESCRIPTION_KEY];
            description = (description == nil) ? kcsError : description;
            
            NSString* kcsErrorCode = [errorValues popObjectForKey:KCS_ERROR_KINVEY_ERROR_CODE_KEY];
            if (kcsErrorCode != nil) {
                [userInfo setValue:kcsErrorCode forKey:KCSErrorCode];
                //if the error is a datalink error, hijack the originating domain and indicate it's a DL error
                if ([kcsErrorCode isKindOfClass:[NSString class]] && [kcsErrorCode isEqualToString:kDatalinkError]) {
                    domain = KCSDatalinkErrorDomain;
                }
            }
            
            NSString* kcsDebugKey = [errorValues popObjectForKey:KCS_ERROR_DEBUG_KEY];
            if (kcsDebugKey != nil) {
                [userInfo setValue:kcsDebugKey forKey:KCSErrorInternalError];
            }
            
            [userInfo setValuesForKeysWithDictionary:errorValues];
            
            kcsErrorDescription = [errorValues popObjectForKey:KCS_ERROR_DESCRIPTION_KEY];
        }
    }
    
    if (description != nil) {
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    }
    
    if (requestId != nil) {
        [userInfo setValue:requestId forKey:KCSRequestId];
    }
    
    if (kcsErrorDescription == nil) {
        if (userInfo[KCSErrorInternalError] != nil) {
            userInfo[NSLocalizedFailureReasonErrorKey] = userInfo[KCSErrorInternalError];
        }
    } else {
        userInfo[NSLocalizedFailureReasonErrorKey] = [NSString stringWithFormat:@"JSON Error: %@", kcsErrorDescription];
    }
    
    if (userInfo[NSLocalizedFailureReasonErrorKey] != nil) {
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = @"Retry request based on information in `NSLocalizedFailureReasonErrorKey`";
    }
    
    if (underlyingError != nil) {
        [userInfo setValue:underlyingError forKey:NSUnderlyingErrorKey];
    }
    
    NSError *error = [NSError errorWithDomain:domain code:errorCode userInfo:userInfo];
    return error;
}

+ (NSError*) createError:(NSDictionary*)jsonErrorDictionary
             description:(NSString*)description
               errorCode:(NSInteger)errorCode
                  domain:(NSString*)domain
               requestId:(NSString*)requestId
{
    return [self createError:jsonErrorDictionary
                 description:description
                   errorCode:errorCode
                      domain:domain
                   requestId:requestId
                 sourceError:nil];
}

@end


@implementation NSError (KCSErrorUtilities)
- (instancetype)updateDomain:(NSString *)domain
{
    NSError* error = [NSError errorWithDomain:domain code:self.code userInfo:[self.userInfo copy]];
    return error;
}
@end
