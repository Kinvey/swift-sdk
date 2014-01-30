//
//  NSDictionary+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 3/14/13.
//  Copyright (c) 2013-2014 Kinvey. All rights reserved.
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


#import "NSDictionary+KinveyAdditions.h"
#import "KinveyCoreInternal.h"

@implementation NSDictionary (KinveyAdditions)

- (instancetype) stripKeys:(NSArray*)keys
{
    NSMutableDictionary* copy = [self mutableCopy];
    for (NSString* key in keys) {
        if (copy[key]) {
            copy[key] = @"XXXXXXXXX";
        }
    }
    return copy;
}

- (instancetype) dictionaryByAddingDictionary:(NSDictionary*)dictionary
{
    NSMutableDictionary* md = [self mutableCopy];
    [md addEntriesFromDictionary:dictionary];
    return md;
}

- (NSString*) escapedJSON
{
    NSString* jsonStr = [self JSONRepresentation];
    return [NSString stringByPercentEncodingString:jsonStr];
}

- (NSDictionary*) invert
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            d[obj] = key;
        }
    }];
    return d;
}
@end
