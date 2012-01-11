//
//  KCSErrorUtilities.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSErrorUtilities.h"

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

@end
