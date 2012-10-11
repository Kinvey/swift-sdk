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

- (void) append:(NSString*)appendant ontoKeySet:(NSArray*)keys recursive:(BOOL) recursive
{
    NSMutableArray* keysToRemove = [NSMutableArray arrayWithCapacity:self.count];
    NSMutableDictionary* objectsToAdd = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* newKey = key;
        if ([keys containsObject:key]) {
            //found one
            newKey = [key stringByAppendingString:appendant];
            [keysToRemove addObject:key];
            [objectsToAdd setObject:obj forKey:newKey];
        }
        if (recursive) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary* mobj = [[obj mutableCopy] autorelease];
                [mobj append:appendant ontoKeySet:keys recursive:recursive];
                [keysToRemove addObject:key];
                [objectsToAdd setObject:mobj forKey:newKey];
            } else if ([obj isKindOfClass:[NSArray class]]) {
                NSMutableArray* marray = [[obj mutableCopy] autorelease];
                for (id arrayObj in obj) {
                    if ([arrayObj isKindOfClass:[NSDictionary class]]) {
                        NSMutableDictionary* mobj = [[arrayObj mutableCopy] autorelease];
                        [mobj append:appendant ontoKeySet:keys recursive:recursive];
                        [marray replaceObjectAtIndex:[obj indexOfObject:arrayObj] withObject:mobj];
                    }
                }
                [keysToRemove addObject:key];
                [objectsToAdd setObject:marray forKey:newKey];
            }
        }
        
    }];
    [self removeObjectsForKeys:keysToRemove];
    [self addEntriesFromDictionary:objectsToAdd];
}

@end
