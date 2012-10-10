//
//  NSMutableDictionary+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 10/9/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "NSMutableDictionary+KinveyAdditions.h"

@implementation NSMutableDictionary (KinveyAdditions)

- (id) popObjectForKey:(id) key
{
    id obj = [self objectForKey:key];
    if (obj) {
        [self removeObjectForKey:key];
    }
    return obj;
}

@end
