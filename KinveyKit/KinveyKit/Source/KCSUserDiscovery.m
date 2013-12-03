//
//  KCSUserDiscovery.m
//  KinveyKit
//
//  Created by Michael Katz on 7/13/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
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
#import "NSArray+KinveyAdditions.h"
#import "KCSObjectMapper.h"

@implementation KCSUserDiscovery

+ (void) lookupUsersForFieldsAndValues:(NSDictionary*)fieldMatchDictionary completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    KCSCollection* userCollection = [KCSCollection userCollection];
    KCSRESTRequest* request = [userCollection restRequestForMethod:kPostRESTMethod apiEndpoint:@"_lookup"];
    [request setJsonBody:fieldMatchDictionary];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        id jsonData = [response jsonResponseValue];
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:(NSDictionary*)jsonData description:@"Lookup was unsuccessful." errorCode:response.responseCode domain:KCSUserErrorDomain requestId:response.requestId];
            completionBlock(nil, error);
            return;
        }
        NSArray* jsonArray = [NSArray wrapIfNotArray:jsonData];
        NSUInteger itemCount = jsonArray.count;
        if (itemCount == 0) {
            completionBlock(@[], nil);
        }
        NSMutableArray* returnObjects = [NSMutableArray arrayWithCapacity:itemCount];
        for (NSDictionary* jsonDict in jsonArray) {
            id newobj = [KCSObjectMapper makeObjectOfType:userCollection.objectTemplate withData:jsonDict];
            [returnObjects addObject:newobj];
        }
        
        completionBlock(returnObjects, nil);
    };

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        completionBlock(nil, error);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connectionProgress) {
        if (progressBlock != nil) {
            progressBlock(@[], connectionProgress.percentComplete);
        }
    };

    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

@end
