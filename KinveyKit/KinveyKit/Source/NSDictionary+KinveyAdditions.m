//
//  NSDictionary+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 3/14/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "NSDictionary+KinveyAdditions.h"

@implementation NSDictionary (KinveyAdditions)

- (NSDictionary*) stripKeys:(NSArray*)keys
{
    NSMutableDictionary* copy = [self mutableCopy];
    for (NSString* key in keys) {
        if (copy[key]) {
            copy[key] = @"XXXXXXXXX";
        }
    }
    return copy;
}
@end
