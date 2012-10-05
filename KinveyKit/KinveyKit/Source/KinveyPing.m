//
//  KinveyPing.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/30/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KinveyPing.h"
#import "KinveyBlocks.h"
#import "KCSRESTRequest.h"
#import "KCSConnectionResponse.h"
#import "KCS_SBJson.h"
#import "KCSClient.h"
#import "KCSReachability.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KinveyHTTPStatusCodes.h"

typedef void(^KCSCommonPingBlock)(BOOL didSucceed, KCSConnectionResponse *response, NSError *error);

@interface KCSPing (private)
+ (void)commonPingHelper:(KCSCommonPingBlock)onComplete;
@end

@implementation KCSPingResult

@synthesize description=_description;
@synthesize pingWasSuccessful=_pingWasSuccessful;

- (id)initWithDescription:(NSString *)description withResult:(BOOL)result
{
    self = [super init];
    if (self){
        _description=[description copy];
        _pingWasSuccessful=result;
    }
    return self;
}

- (void)dealloc
{
    [_description release];
    [super dealloc];
}

@end

@implementation KCSPing

#if TARGET_OS_IPHONE
// NETWORK checks for iPhone
+ (BOOL)networkIsReachable
{
    KCSReachability *reachability = [[KCSClient sharedClient] networkReachability];
    return [reachability isReachable];
}

+ (BOOL)kinveyServiceIsReachable
{
    KCSReachability *reachability = [[KCSClient sharedClient] kinveyReachability];
    return [reachability isReachable];    
}
#else
// NETWORK checks for Mac OS-X, stub to true
+ (BOOL)networkIsReachable
{
    return YES;
}

+ (BOOL)kinveyServiceIsReachable
{
    return YES;
}
#endif



+ (void)commonPingHelper:(KCSCommonPingBlock)onComplete
{
    // Verify network hardware...
    if ([KCSPing networkIsReachable] && [KCSPing kinveyServiceIsReachable]){
        
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            if (response.responseCode == KCS_HTTP_STATUS_OK){
                onComplete(YES, response, nil);                
            } else {
                NSDictionary *jsonResponse = (NSDictionary*) [response jsonResponseValue];
                NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Unable to Ping Kinvey" errorCode:response.responseCode domain:KCSNetworkErrorDomain];
                onComplete(NO, nil, error);
            }

        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            onComplete(NO, nil, error);
        };
        
        // Dummy
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] appdataBaseURL] usingMethod:kGetRESTMethod];
        [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
    } else {
        NSString *description;
        NSInteger errorCode;
        if ([KCSPing networkIsReachable]){
            errorCode = KCSKinveyUnreachableError;
            description = @"Unable to reach Kinvey service.";
        } else {
            errorCode = KCSNetworkUnreachableError;
            description = @"Unable to reach network.";
        }
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:description
                                                                           withFailureReason:@"Reachability determined that either Kinvey or the network was not reachable"
                                                                      withRecoverySuggestion:@"Check to make sure device is not in Airplane mode and has a signal or try again later"
                                                                         withRecoveryOptions:nil];
        NSError *error = [NSError errorWithDomain:KCSNetworkErrorDomain
                                             code:errorCode
                                         userInfo:userInfo];
        
        onComplete(NO, nil, error);
    }

}

+ (void)checkKinveyServiceStatusWithAction: (KCSPingBlock)completionAction
{
    KCSCommonPingBlock cpb = ^(BOOL didSucceed, KCSConnectionResponse *response, NSError *error){
        NSString *description = nil;
        if (didSucceed){
            description = [NSString stringWithFormat:@"Kinvey Service is Alive"];
        } else {
            description = [NSString stringWithFormat:@"%@, %@, %@", error.localizedDescription, error.localizedFailureReason, error.localizedRecoveryOptions];
        }
        
        completionAction([[[KCSPingResult alloc] initWithDescription:description withResult:didSucceed] autorelease]);
    };
    
    [KCSPing commonPingHelper:cpb];
}

// Pings
+ (void)pingKinveyWithBlock: (KCSPingBlock)completionAction
{
    KCSCommonPingBlock cpb = ^(BOOL didSucceed, KCSConnectionResponse *response, NSError *error){
        NSString *description = nil;
        if (didSucceed){
            NSDictionary *jsonData = (NSDictionary*) [response jsonResponseValue];
            NSNumber *useOldStyle = [[[KCSClient sharedClient] options] valueForKey:KCS_USE_OLD_PING_STYLE_KEY];
            if ([useOldStyle boolValue]){
                description = [jsonData description];
            } else {
                description = [NSString stringWithFormat:@"Kinvey Service is alive, version: %@, response: %@",
                               [jsonData valueForKey:@"version"], [jsonData valueForKey:@"kinvey"]];
            }
        } else {
            description = [NSString stringWithFormat:@"%@, %@, %@", error.localizedDescription, error.localizedFailureReason, error.localizedRecoveryOptions];
        }

        completionAction([[[KCSPingResult alloc] initWithDescription:description withResult:didSucceed] autorelease]);
    };

    [KCSPing commonPingHelper:cpb];
}

@end
