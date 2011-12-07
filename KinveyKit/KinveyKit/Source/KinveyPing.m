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

+ (void)pingKinveyWithBlock: (KCSPingBlock)completionAction
{
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        // The ping worked!
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        completionAction([[[KCSPingResult alloc] initWithDescription:[jsonData description] withResult:YES] autorelease]);
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        // Ping failed!
        completionAction([[[KCSPingResult alloc] initWithDescription:[error description] withResult:NO] autorelease]);
    };
    
    // Dummy
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] dataBaseURL] usingMethod:kGetRESTMethod];
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

@end
