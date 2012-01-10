//
//  KinveyPing.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/30/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyPing.h"
#import "KinveyBlocks.h"
#import "KCSRESTRequest.h"
#import "KCSConnectionResponse.h"
#import "JSONKit.h"
#import "KCSClient.h"
#import "KCSReachability.h"

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
//// NETWORK checks for iPhone
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
//// NETWORK checks for Mac OS-X, stub to true
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
            onComplete(YES, response, nil);
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            onComplete(NO, nil, error);
        };
        
        // Dummy
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] appdataBaseURL] usingMethod:kGetRESTMethod];
        [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Network is not reachable at this time." forKey:NSLocalizedDescriptionKey];
        onComplete(NO, nil, [NSError errorWithDomain:@"KINVEY NETWORK ERROR" code:100 userInfo:userInfo]);
    }

}

+ (void)checkKinveyServiceStatusWithAction: (KCSPingBlock)completionAction
{
    KCSCommonPingBlock cpb = ^(BOOL didSucceed, KCSConnectionResponse *response, NSError *error){
        NSString *description = nil;
        if (didSucceed){
            description = [NSString stringWithFormat:@"Kinvey Service is Alive"];
        } else {
            description = [error localizedDescription];
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
            NSDictionary *jsonData = [response.responseData objectFromJSONData];
            NSNumber *useOldStyle = [[[KCSClient sharedClient] options] valueForKey:KCS_USE_OLD_PING_STYLE_KEY];
            if ([useOldStyle boolValue]){
                description = [jsonData description];
            } else {
                description = [NSString stringWithFormat:@"Kinvey Service is alive, version: %@, response: %@",
                               [jsonData valueForKey:@"version"], [jsonData valueForKey:@"kinvey"]];
            }
        } else {
            description = [error localizedDescription];
        }

        completionAction([[[KCSPingResult alloc] initWithDescription:description withResult:didSucceed] autorelease]);
    };

    [KCSPing commonPingHelper:cpb];
}

@end
