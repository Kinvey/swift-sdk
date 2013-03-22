//
//  KCSFacebookHelper.m
//  KinveyKit
//
//  Created by Michael Katz on 3/22/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSFacebookHelper.h"

#import "KCSAppdataStore.h"
#import "KinveyEntity.h"

@implementation KCSFacebookHelper

+ (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [kv[1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[val] = kv[0];
    }
    return params;
}

+ (NSDictionary*) parseDeepLink:(NSURL*)url
{
    NSString* query = [url query];
    NSMutableDictionary* d = [NSMutableDictionary d];
    NSDictionary* params = [self parseURLParams:query];
    if (params.count > 0) {
        NSString* targetURL = params[@"target_url"];
        if (targetURL != nil) {
            //target URL should be in the form:
            //http://baas.kinvey.com/rpc/:kid/:OGCollection/:id/:category/_objView.html
            //                      / 0 / 1  /     2       / 3 /   4     / 5
            NSArray* subpieces = [targetURLString pathComponents];
            NSString* deeplink = subpieces.count >= 5 ? subpieces[5] : nil;
            
            // Check for the 'deeplink' parameter to check if this is one of
            if (deeplink != nil) {
                NSString* action = deeplink[2];
                NSString* entityId = deeplink[3];
                NSString* objectType = deeplink[4];
                if (action != nil && entityId != nil && objectType != nil) {
                    d[KCSFacebookOGAction] = action;
                    d[KCSFacebookOGObjectType] = objectType;
                    d[KCSFacebookOGEntityId] = entityId;
                }
            }
        }
    }
    return [d copy];
}

+ (void) publishToOpenGraph:(NSString*)entityId action:(NSString*)action objectType:(NSString*)objectType optionalParams:(NSDictionary*)extraParams
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:@{KCSStoreKeyCollectionName : action,
                           KCSStoreKeyCollectionTemplateClass : [NSMutableDictionary class],
                              
                              }];
    dict[KCSEntityKeyId] = objectType;
    dict[KCSFacebookOGEntityId] = entityId;
    if (extraParams != nil) {
        [dict addEntriesFromDictionary:extraParams];
    }
    [store saveObject:dict withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //TODO: handle
    } withProgressBlock:nil];
}

@end
