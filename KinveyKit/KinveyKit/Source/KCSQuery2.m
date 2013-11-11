//
//  KCSQuery2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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

#import "KCSQuery2.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

@interface KCSQuery2 ()
@property (nonatomic, retain) NSMutableDictionary* internalRepresentation;
@property (nonatomic, retain) NSMutableArray* mySortDescriptors;
@end

@implementation KCSQuery2

- (instancetype) init
{
    self = [super init];
    if (self) {
        _internalRepresentation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)description
{
    return [self queryString:NO];
}

#pragma mark - directQuery
+ (instancetype) queryMatchField:(NSString*)field toValue:(id)value
{
    KCSQuery2* query = [[KCSQuery2 alloc] init];
    query.internalRepresentation = [@{field:value} mutableCopy];
    return query;
}

#pragma mark - predicates
NSString* kcsPredToQueryStrForKeyPath(NSExpression* expr)
{
    return [expr keyPath];
}

id kcsPredToQueryExprVal(NSExpression* expr)
{
    if (expr.expressionType == NSKeyPathExpressionType) {
        return kcsPredToQueryStrForKeyPath(expr);
    }
    return nil;
}

+ (instancetype) queryWithPredicate:(NSPredicate*)predicate error:(NSError**)error
{
    KCSQuery2* query = nil;
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate* cpredicate = (NSComparisonPredicate*) predicate;
        NSComparisonPredicateModifier modifier = [cpredicate comparisonPredicateModifier];
        //TODO: options
        if (modifier == NSDirectPredicateModifier) {
            NSExpression* lhs = [cpredicate leftExpression];
            NSExpression* rhs = [cpredicate rightExpression];
            NSPredicateOperatorType type = [cpredicate predicateOperatorType];
            if (type == NSEqualToPredicateOperatorType) {
                id field = kcsPredToQueryExprVal(lhs);
                id val = kcsPredToQueryExprVal(rhs);
                if (field != nil && val != nil) {
                    query = [self queryMatchField:field toValue:val];
                } else {
                    //TODO: error
                }
            } else {
                //TODO: error
            }
        } else {
            //TODO: ERROR
        }
    } else {
        //TODO: error
    }
    return query;
}


#pragma mark - sorting
- (NSArray *)sortDescriptors
{
    return [_mySortDescriptors copy];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
    _mySortDescriptors = [NSMutableArray arrayWithCapacity:sortDescriptors.count];
    for (NSSortDescriptor* sort in sortDescriptors) {
        if (sort.comparator != nil) {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot use a comparator with Kinvey backend" userInfo:@{@"invalidSort":sort}] raise];
        }
        if (sort.selector != @selector(compare:)) {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot use a selector with Kinvey backend" userInfo:@{@"invalidSort":sort}] raise];
        }
        [_mySortDescriptors addObject:sort];
    }
}

//TODO handle backend vs client property name
- (NSString*) sortString:(BOOL)escape
{
    NSString* sortString = @"";
    if ([_mySortDescriptors count] > 0) {
        NSMutableDictionary* sortDictionary = [NSMutableDictionary dictionary];
        for (NSSortDescriptor* sort in _mySortDescriptors) {
            NSNumber* direction = sort.ascending ? @(1) : @(-1);
            NSString* key = sort.key;
            sortDictionary[key] = direction;
        }
        sortString = [NSString stringWithFormat:@"&sort=%@", escape ? [sortDictionary escapedJSON] : [sortDictionary JSONRepresentation]];
    }
    
    return sortString;
}

#pragma mark - stringification

- (NSString*) queryString:(BOOL)escape
{
    NSString* query =  [NSString stringWithFormat:@"query=%@", escape ? [_internalRepresentation escapedJSON] : [_internalRepresentation JSONRepresentation]];
    query = [query stringByAppendingString:[self sortString:escape]];
    return query;
}

- (NSString *)escapedQueryString
{
    return [self queryString:YES];
}

- (NSString*) keyString
{
    NSString* ir = [_internalRepresentation JSONRepresentation];
    return [@([ir hash]) stringValue];
}

#pragma mark - Compatability

+ (instancetype) queryWithQuery1:(KCSQuery *)query
{
    KCSQuery2* q = [[self alloc] init];
    q.internalRepresentation = [query.query mutableCopy];
    
    NSMutableArray* sorts = [NSMutableArray arrayWithCapacity:query.sortModifiers.count];
    for (KCSQuerySortModifier* mod in query.sortModifiers) {
        NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:mod.field ascending:sort.ascending == kKCSAscending];
        [sorts addObject:sort];
    }
    return q;
}

@end
