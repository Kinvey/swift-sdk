//
//  KCSBuilders.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSBuilders.h"

@implementation KCSAttributedStringBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSAttributedString*)object string];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSAttributedString class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        
        return [[[NSAttributedString alloc] initWithString:object] autorelease];
    }
    return [NSNull null];
}
@end
@implementation KCSMAttributedStringBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSAttributedString class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        
        return [[[NSMutableAttributedString alloc] initWithString:object] autorelease];
    }
    return [NSNull null];
}
@end

#import "NSDate+ISO8601.h"
@implementation KCSDateBuilder
+ (id) JSONCompatabileValueForObject:(id)object
{
    return [NSString stringWithFormat:@"ISODate(%c%@%c)", '"', [object stringWithISO8601Encoding], '"'];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSDate class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        NSString *tmp = [(NSString *)object stringByReplacingOccurrencesOfString:@"ISODate(\"" withString:@""];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\")" withString:@""];
        NSDate *date = [NSDate dateFromISO8601EncodedString:tmp];
        return date;
    }
    return [NSNull null];
}
@end

@implementation KCSSetBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSSet*)object allObjects];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSSet setWithArray:object];
    }
    return [NSNull null];
}
@end
@implementation KCSMSetBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSMutableSet setWithArray:object];
    }
    return [NSNull null];
}
@end

@implementation KCSOrderedSetBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSOrderedSet*)object array];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSOrderedSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSOrderedSet orderedSetWithArray:object];
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [NSOrderedSet orderedSetWithSet:object];
    }
    return [NSNull null];
}
@end
@implementation KCSMOrderedSetBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSOrderedSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSMutableOrderedSet orderedSetWithArray:object];
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [NSMutableOrderedSet orderedSetWithSet:object];
    }
    return [NSNull null];
}
@end

@implementation KCSBuilders

@end
