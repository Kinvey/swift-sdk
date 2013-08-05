//
//  NSArray+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "NSArray+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"

@implementation NSArray (KinveyAdditions)

- (NSString *)join:(NSString *)delimiter
{
    NSMutableString* string = [NSMutableString string];
    for (int i=0; i < self.count; i++) {
        if (i > 0) {
            [string appendFormat:@"%@%@",delimiter,[self objectAtIndex:i]];
        } else {
            [string appendFormat:@"%@",[self objectAtIndex:i]];
        }
    }
    return string;
}

+ (instancetype) wrapIfNotArray:(id)object
{
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if ([object isKindOfClass:[NSArray class]]){
        return object;
    } else if ([object isKindOfClass:[NSSet class]]){
        return [object allObjects];
    } else if ([object isKindOfClass:[NSOrderedSet class]]){
        return [object array];
    } else {
        return object == nil? @[] : @[object];
    }
}

+ (instancetype) arrayWithObjectOrNil:(id) object
{
    return object == nil ? @[] : @[object];
}

+ (instancetype) arrayIfDictionary:(id)object
{
    if ([object isKindOfClass:[NSArray class]]){
        return (NSArray *)object;
    } else if ([(NSDictionary *)object count] == 0) {
            return @[];
        } else {
            return @[object];
        }
}

+ (instancetype) arrayWith:(NSUInteger)num copiesOf:(id<NSCopying>)val
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:num];
    for (int i=0; i<num; i++) {
        array[i] = [val copyWithZone:NULL];
    }
    return array;
}

- (instancetype) arrayByPercentEncoding
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:self.count];
    for (NSString* s in self) {
        [array addObject:[NSString stringByPercentEncodingString:s]];
    }
    return array;
}

@end
