    //
//  NSArray+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "NSArray+KinveyAdditions.h"

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

+ (NSArray*) wrapIfNotArray:(id)object
{
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if ([object isKindOfClass:[NSArray class]]){
        return object;
    } else {
        return object == nil? @[] : @[object];
    }
}

+ (NSArray*) arrayWithObjectOrNil:(id) object
{
    return object == nil ? @[] : @[object];
}

+ (NSArray *) arrayIfDictionary:(id)object
{
    if ([object isKindOfClass:[NSArray class]]){
        return (NSArray *)object;
    } else if ([(NSDictionary *)object count] == 0) {
            return @[];
        } else {
            return @[object];
        }
}

@end
