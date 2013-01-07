//
//  KCSUserDiscovery.m
//  KinveyKit
//
//  Created by Michael Katz on 7/13/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSUserDiscovery.h"
#import "KinveyUser.h"
#import "KCSHiddenMethods.h"
#import "KinveyBlocks.h"
#import "KCSConnectionProgress.h"
#import "KCSConnectionResponse.h"
#import "KCSLogManager.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "KinveyCollection.h"

@implementation KCSUserDiscovery

+ (void) lookupUsersForFieldsAndValues:(NSDictionary*)fieldMatchDictionary completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    KCSCollection* userCollection = [KCSCollection userCollection];
    KCSRESTRequest* request = [userCollection restRequestForMethod:kPostRESTMethod apiEndpoint:@"_lookup"];
    [request setJsonBody:fieldMatchDictionary];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        NSObject* jsonData = [response jsonResponseValue];
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:(NSDictionary*)jsonData description:@"Lookup was unsuccessful." errorCode:response.responseCode domain:KCSUserErrorDomain requestId:response.requestId];
            completionBlock(nil, error);
            return;
        }
        NSArray* jsonArray = nil;
        if ([jsonData isKindOfClass:[NSArray class]]){
            jsonArray = (NSArray *)jsonData;
        } else {
            if ([(NSDictionary *)jsonData count] == 0){
                jsonArray = [NSArray array];
            } else {
                jsonArray = [NSArray arrayWithObjects:(NSDictionary *)jsonData, nil];
            }
        }        
        
        completionBlock(jsonArray, nil);
    };
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        completionBlock(nil, error);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connectionProgress) {
        if (progressBlock != nil) {
            //TODO:progressBlock(connectionProgress.objects, connectionProgress.percentComplete);
            progressBlock(@[], connectionProgress.percentComplete);
        }
    };

    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

@end
