//
//  KCSCustomEndpoints.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSCustomEndpoints.h"

#import "KinveyUser.h"

#import "KCSRequest.h"
#import "KCS_SBJson.h"
#import "KCSUser+KinveyKit2.h"


@implementation KCSCustomEndpoints

+ (void) callEndpoint:(NSString*)endpoint params:(NSDictionary*)params completionBlock:(void (^)(id results, NSError* error))completionBlock
{
    
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodPOST;
    request.contextRoot = kKCSContextRPC;
    request.pathComponents = @[@"custom",endpoint];
    
    request.body = params ? params : @{};
    request.authorization = [KCSUser activeUser];
    
    [request run:^(id results, NSError *error) {
        completionBlock(results, error);
    }];
}


@end
