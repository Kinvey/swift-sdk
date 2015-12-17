//
//  KCSUser__RLMObject.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-11-24.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCSUserRealm.h"

@implementation KCSUserRealm

+(NSString *)primaryKey
{
    return @"userId";
}

+(instancetype)createInRealm:(RLMRealm *)realm withValue:(id)value
{
    return [super createInRealm:realm
                      withValue:value];
}

+ (instancetype)createOrUpdateInRealm:(RLMRealm *)realm withValue:(id)value
{
    NSDictionary* dict = @{@"userId"   : value[@"_id"],
                           @"username" : value[@"username"],
                           @"acl"      : value[@"_acl"],
                           @"metadata" : value[@"_kmd"]};
    return [super createOrUpdateInRealm:realm
                              withValue:dict];
}

@end
