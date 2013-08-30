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
#import "NSString+KinveyAdditions.h"

#import "KCS_SBJson.h"

@interface KCSQuery2 ()
@property (nonatomic, retain) NSMutableDictionary* internalRepresentation;
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
    return [self queryString];
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


#pragma mark - stringification

- (NSString*) queryString
{
    return [NSString stringWithFormat:@"query=%@", [_internalRepresentation JSONRepresentation]];
}

- (NSString *)escapedQueryString
{
    return [NSString stringByPercentEncodingString:[self queryString]];
}


@end
