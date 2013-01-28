//
//  KCSGroup.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSGroup.h"
@interface KCSGroup () {
@private
    NSArray* _array;
    NSString* _key;
    NSArray* _queriedFields;
}

@end

@implementation KCSGroup

- (id) initWithJsonArray:(NSArray*)jsonData valueKey:(NSString*)key queriedFields:(NSArray*)fields;
{
    self = [super init];
    if (self) {
        _array = [jsonData copy];
       
        if (fields.count == 0) {
            NSMutableArray* fieldValues = [NSMutableArray array];
            for (NSDictionary* d in jsonData) {
                NSMutableArray* keys = [[d allKeys] mutableCopy];
                [keys removeObject:key];
                [fieldValues addObjectsFromArray:keys];
            }
            _queriedFields = [NSArray arrayWithArray:fieldValues];
        } else {
            _queriedFields = [NSArray arrayWithArray:fields];
        }
        _key = [key copy];
    }
    return self;
}

- (NSArray*) fieldsAndValues
{
    return _array;
}

- (NSString*) returnValueKey
{
    return _key;
}

- (id) reducedValueForFields:(NSDictionary*)fields
{
    __block NSNumber* number = [NSNumber numberWithInt:NSNotFound];
    [self enumerateWithBlock:^(NSArray *fieldValues, id value, NSUInteger idx, BOOL *stop) {
        BOOL found = NO;
        for (NSString* field in [fields allKeys]) {
            if ([_queriedFields containsObject:field] && [[fieldValues objectAtIndex:[_queriedFields indexOfObject:field]] isEqual:[fields objectForKey:field]]) {
                found = YES;
            } else {
                found = NO;
                break;
            }
        }
        if (found) {
            *stop = YES;
            number = value;
        }
    }];
    return number;
}

- (void) enumerateWithBlock:(void (^)(NSArray* fieldValues, id value, NSUInteger idx, BOOL *stop))block
{
    [_array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary* result = obj;
        NSMutableArray* fieldValues = [NSMutableArray arrayWithCapacity:result.count - 1];
        for (NSString* field in _queriedFields) {
            [fieldValues addObject:[result objectForKey:field]];
        }
        block([NSArray arrayWithArray:fieldValues], [result objectForKey:_key], idx, stop);
    }];
}

@end
