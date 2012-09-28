//
//  KCSQuery.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSQuery.h"
#import "KCSLogManager.h"
#import "SBJson.h"
#import "NSString+KinveyAdditions.h"
#import "NSArray+KinveyAdditions.h"
#import "KinveyPersistable.h"

#pragma mark -
#pragma mark KCSQuerySortModifier
@implementation KCSQuerySortModifier
@synthesize field = _field;
@synthesize direction = _direction;

- (id)initWithField:(NSString *)field inDirection:(KCSSortDirection)direction
{
    self = [super init];
    if (self){
        _field = [field retain];
        _direction = direction;
    }
    return self;
}

- (void)dealloc {
    [_field release];
    [super dealloc];
}

@end

#pragma mark -
#pragma mark KCSQueryLimitModifier
@implementation KCSQueryLimitModifier
@synthesize limit = _limit;
- (id)initWithLimit:(NSInteger)limit
{
    self = [super init];
    if (self){
        _limit = limit;
    }
    return self;
}

- (NSString *)parameterStringRepresentation
{
    KCSLogDebug(@"Limit String: %@", [NSString stringWithFormat:@"limit=%d", self.limit]);
    return [NSString stringWithFormat:@"limit=%d", self.limit];
    
}

@end

#pragma mark -
#pragma mark KCSQuerySkipModifier
@implementation KCSQuerySkipModifier
@synthesize count = _count;

-(id)initWithcount:(NSInteger)count
{
    self = [super init];
    if (self){
        _count = count;
    }
    return self;
}

- (NSString *)parameterStringRepresentation
{
    KCSLogDebug(@"Count String: %@", [NSString stringWithFormat:@"skip=%d", self.count]);
    return [NSString stringWithFormat:@"skip=%d", self.count];
}

@end

#pragma mark -
#pragma mark Private Interface

// Private interface
@interface KCSQuery ()
@property (nonatomic, readwrite, copy) NSMutableDictionary *query;
@property (nonatomic, retain) KCS_SBJsonWriter *JSONwriter;
@property (nonatomic, retain, readwrite) NSArray *sortModifiers;
@property (nonatomic, retain) NSArray* referenceFieldsToResolve;


NSString *KCSConditionalStringFromEnum(KCSQueryConditional conditional);

+ (NSDictionary *)queryDictionaryWithFieldname: (NSString *)fieldname operation:(KCSQueryConditional)op forQueries:(NSArray *)queries useQueriesForOps: (BOOL)useQueriesForOps;


@end

#pragma mark -
#pragma mark KCSQuery Implementation

@implementation KCSQuery

NSString *
KCSConditionalStringFromEnum(KCSQueryConditional conditional)
{
    static NSDictionary *KCSOperationStringLookup = nil;
    
    if (KCSOperationStringLookup == nil){
        KCSOperationStringLookup = [@{
                                    // Basic Queries
                                    @(kKCSLessThan)           : @"$lt",
                                    @(kKCSLessThanOrEqual)    : @"$lte",
                                    @(kKCSGreaterThan)        : @"$gt",
                                    @(kKCSGreaterThanOrEqual) : @"$gte",
                                    @(kKCSNotEqual)           : @"$ne",
                                    
                                    // Geo Queries
                                    @(kKCSNearSphere)         : @"$nearSphere",
                                    @(kKCSWithinBox)          : @"$box",
                                    @(kKCSWithinCenterSphere) : @"$centerSphere",
                                    @(kKCSWithinPolygon)      : @"$polygon",
                                    @(kKCSMaxDistance)        : @"$maxDistance",
                                    
                                    // String Operators
                                    @(kKCSRegex) : @"$regex",
                                    
                                    // Joining Operators
                                    @(kKCSIn)    : @"$in",
                                    @(kKCSOr)    : @"$or",
                                    @(kKCSAnd)   : @"XXX",
                                    @(kKCSNotIn) : @"$nin",
                                    
                                    // Array Operators
                                    @(kKCSAll)  : @"$all",
                                    @(kKCSSize) : @"$size",
                                    
                                    // Arbitrary Operators
                                    @(kKCSWhere) : @"$where",
                                    
                                    // Internal Operators
                                    @(kKCSWithin)  : @"$within",
                                    @(kKCSOptions) : @"$options"} retain];
    }
    return [KCSOperationStringLookup objectForKey:@(conditional)];
}

+ (NSDictionary *)queryDictionaryWithFieldname: (NSString *)fieldname operation:(KCSQueryConditional)op forQueries:(NSArray *)queries useQueriesForOps: (BOOL)useQueriesForOps
{
    NSDictionary *query = nil;
    NSString *opName = KCSConditionalStringFromEnum(op);
    
    if (useQueriesForOps == YES){
        op = kKCSMulti;
    }
    
    switch (op) {
            
            // These guys all have the extra nesting
        case kKCSNearSphere:
        case kKCSWithinBox:
        case kKCSWithinCenterSphere:
        case kKCSWithinPolygon:
            
            if (queries.count > 1){
                // ERROR
                return nil;
            }
            NSString *within = KCSConditionalStringFromEnum(kKCSWithin);
            NSDictionary *geoQ = nil;
            if (op == kKCSNearSphere){
                geoQ = @{ opName : [queries objectAtIndex:0] };
            } else {
                geoQ = @{ within :@{ opName : [queries objectAtIndex:0]}};
            }
            
            //////////// HACK //////////////
            ///// For right now Kinvey has _geoloc as a free indexed property, if the user is using a geoquery now, then we
            ////  rewrite to the correct property, in the future use their passed in property
#if 0
            query = @{fieldname : geoQ};
#else
            query = @{KCSEntityKeyGeolocation : geoQ};
#endif
            ////
            //////////// HACK //////////////
            
            break;
            
            // Interior array ops
        case kKCSIn:
        case kKCSNotIn:
            if (fieldname == nil || queries == nil){
                return nil;
            }
            if (queries.count >0 && [[queries objectAtIndex:0] isKindOfClass:[NSArray class]]) {
                queries = [queries objectAtIndex:0];
            }
            NSDictionary *innerQ = @{opName : queries};
            query = @{fieldname : innerQ};
            
            break;
            // Exterior array ops
        case kKCSOr:
            
            if (fieldname != nil || queries == nil){
                KCSLogWarning(@"Fieldname was not nil (was %@) for a joining op, this is unexpected", fieldname);
                return nil;
            }
            
            query = @{opName : queries};
            
            break;
            
            // This is the case where we're doing a direct match
        case kKCSNOOP:
            
            if (fieldname == nil || queries == nil || queries.count > 1){
                // ERROR!
                return nil;
            }
            query = @{ fieldname : [queries objectAtIndex:0]};
            break;
            
        case kKCSLessThan:
        case kKCSLessThanOrEqual:
        case kKCSGreaterThan:
        case kKCSGreaterThanOrEqual:
        case kKCSNotEqual:
        case kKCSRegex:
        case kKCSMulti:
            
            if (fieldname == nil){
                // Error
                return nil;
            }
            
            if (!useQueriesForOps){
                if (op == kKCSNOOP || queries == nil || queries.count > 1){
                    // Error
                    return nil;
                }
                
                query = @{ fieldname : @{ opName : [queries objectAtIndex:0]} };
            } else {
                BOOL isGeoQuery = NO;
                if (op != kKCSMulti || queries == nil){
                    // Error
                    return nil;
                }
                
                NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
                for (NSDictionary *pair in queries) {
                    KCSQueryConditional thisOp = [[pair objectForKey:@"op"] intValue];
                    NSObject *q = [pair objectForKey:@"query"];
                    [tmp setObject:q forKey:KCSConditionalStringFromEnum(thisOp)];
                    
                    // Make sure to account for Geo Queries in this version of KCS
                    switch(thisOp){
                        case kKCSNearSphere:
                        case kKCSWithinBox:
                        case kKCSWithinCenterSphere:
                        case kKCSWithinPolygon:
                        case kKCSMaxDistance:
                            isGeoQuery = YES;
                            break;
                        default:
                            break;
                    }
                }
                
                if (isGeoQuery){
                    //////////// HACK //////////////
                    ///// For right now Kinvey has _geoloc as a free indexed property, if the user is using a geoquery now, then we
                    ////  rewrite to the correct property, in the future use their passed in property
#if 0
                    query = @{fieldname : tmp};
#else
                    query = @{KCSEntityKeyGeolocation : tmp};
#endif
                    ////
                    //////////// HACK //////////////
                } else {
                    
                    query = [NSDictionary dictionaryWithObject:tmp forKey:fieldname];
                }
                
            }
            break;
            
            
            // These are not yet implemented...
        case kKCSAll:
        case kKCSSize:
        case kKCSWhere:
            return nil;
            break;
            
        default:
            break;
    }
    
    return query;
}

#pragma mark - iVars
@synthesize query = _query;
@synthesize JSONwriter = _JSONwriter;
@synthesize sortModifiers = _sortModifiers;
@synthesize limitModifer = _limitModifer;
@synthesize skipModifier = _skipModifier;
@synthesize referenceFieldsToResolve = _referenceFieldsToResolve;

- (id)init
{
    self = [super init];
    if (self){
        _JSONwriter = [[KCS_SBJsonWriter alloc] init];
        _query = [[NSMutableDictionary dictionary] retain];
        _sortModifiers = [@[] retain];
        _referenceFieldsToResolve = [@[] retain];
    }
    return self;
}

- (void)dealloc
{
    [_JSONwriter release];
    [_query release];
    [_limitModifer release];
    [_skipModifier release];
    [_sortModifiers release];
    [_referenceFieldsToResolve release];
    _limitModifer = nil;
    _skipModifier = nil;
    _sortModifiers = nil;
    _JSONwriter = nil;
    _query = nil;
    [super dealloc];
}

- (void)setQuery:(NSMutableDictionary *)query
{
    if (_query == query){
        return;
    }
    NSMutableDictionary *oldDict = _query;
    _query = [query mutableCopy];
    [oldDict release];
}


#pragma mark - Creating Queries
+ (KCSQuery *) queryOnField:(NSString*)field withRegex:(NSString*)expression options:(KCSRegexpQueryOptions)options
{
    if (options == 0) {
        return [self queryOnField:field usingConditional:kKCSRegex forValue:expression];
    } else {
        NSMutableString* optionsString = [NSMutableString string];
        if (options & kKCSRegexpCaseInsensitive) {
            [optionsString appendString:@"i"];
        }
        if (options & kKCSRegexpAllowCommentsAndWhitespace) {
            [optionsString appendString:@"x"];
        }
        if (options & kKCSRegexpDotMatchesAll) {
            [optionsString appendString:@"s"];
        }
        if (options & kKCSRegexpAnchorsMatchLines) {
            [optionsString appendString:@"m"];
        }
        return [self queryOnField:field usingConditionalsForValues:kKCSRegex, expression, kKCSOptions, optionsString, nil];
    }
}

+ (KCSQuery *)queryOnField:(NSString*)field withRegex:(NSString*)expression
{
    return [self queryOnField:field withRegex:expression options:kKCSRegexepDefault];
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value
{
    KCSQuery *query = [[[KCSQuery alloc] init] autorelease];
    
    query.query = [[[KCSQuery queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO] mutableCopy] autorelease];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field withExactMatchForValue: (NSObject *)value
{
    KCSQuery *query = [[[KCSQuery alloc] init] autorelease];
    
    query.query = [[[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[value] useQueriesForOps:NO] mutableCopy] autorelease];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ...
{
    NSMutableArray *args = [NSMutableArray array];
    va_list items;
    va_start(items, firstConditional);
    
    KCSQueryConditional currentCondition = firstConditional;
    NSObject *currentQuery = va_arg(items, NSObject *);
    
    while (currentCondition && currentQuery){
        NSDictionary *pair = @{ @"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
        currentCondition = va_arg(items, KCSQueryConditional);
        currentQuery = va_arg(items, NSObject *);
    }
    va_end(items);
    
    KCSQuery *query = [[[KCSQuery alloc] init] autorelease];
    
    query.query = [[[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES] mutableCopy] autorelease];
    
    return query;
    
}

+ (KCSQuery *)queryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ...
{
    NSMutableArray *queries = [NSMutableArray array];
    va_list args;
    va_start(args, firstQuery);
    for (KCSQuery *arg = firstQuery; arg != nil; arg = va_arg(args, KCSQuery *)){
        [queries addObject:arg.query];
    }
    va_end(args);
    
    KCSQuery *query = [[[KCSQuery alloc] init] autorelease];
    
    query.query = [[[KCSQuery queryDictionaryWithFieldname:nil operation:joiningOperator forQueries:queries useQueriesForOps:NO] mutableCopy] autorelease];
    
    return query;
    
    
}

+ (KCSQuery *)queryNegatingQuery:(KCSQuery *)query
{
    KCSQuery *q = [[[KCSQuery alloc] init] autorelease];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // We need to take each key in query and replace the value with a dictionary containing the key $not and the old value
    for (NSString *field in query.query) {
        NSObject *oldQuery = [query.query objectForKey:field];
        [dict setObject:@{@"$not" : oldQuery} forKey:field];
    }
    
    q.query = dict;
    
    return q;
}

+ (KCSQuery *)queryForNilValueInField: (NSString *)field
{
    /////// MEGA SPECIAL CASE
    NSDictionary *exists = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"$in", [NSNumber numberWithBool:YES], @"$exists", nil];
    NSDictionary *query = [NSDictionary dictionaryWithObject:exists forKey:field];
    KCSQuery *q = [[[KCSQuery alloc] init] autorelease];
    q.query = [[query mutableCopy] autorelease];
    return q;
}

+ (KCSQuery *)query
{
    KCSQuery *query = [[[KCSQuery alloc] init] autorelease];
    return query;
}


#pragma mark -
#pragma mark Modifying Queries
- (void)addQuery: (KCSQuery *)query
{
    for (NSString *key in query.query) {
        [self.query setObject:[query.query objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value
{
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO];
    
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field withExactMatchForValue: (NSObject *)value
{
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[value] useQueriesForOps:NO];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ...
{
    NSMutableArray *args = [NSMutableArray array];
    va_list items;
    va_start(items, firstConditional);
    
    KCSQueryConditional currentCondition = firstConditional;
    NSObject *currentQuery = va_arg(items, NSObject *);
    
    while (currentCondition && currentQuery){
        NSDictionary *pair = @{@"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
        currentCondition = va_arg(items, KCSQueryConditional);
        currentQuery = va_arg(items, NSObject *);
        
    }
    va_end(items);
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ...
{
    NSMutableArray *queries = [NSMutableArray array];
    va_list args;
    va_start(args, firstQuery);
    for (KCSQuery *arg = firstQuery; arg != nil; arg = va_arg(args, KCSQuery *)){
        [queries addObject:arg.query];
    }
    va_end(args);
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:nil operation:joiningOperator forQueries:queries useQueriesForOps:NO];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryNegatingQuery:(KCSQuery *)query
{
    // We need to take each key in query and replace the value with a dictionary containing the key $not and the old value
    for (NSString *field in query.query) {
        NSObject *oldQuery = [query.query objectForKey:field];
        [self.query setObject:@{@"$not" : oldQuery} forKey:field];
    }
    
}

- (void)clear
{
    [self.query removeAllObjects];
}


- (void)negateQuery
{
    for (NSString *field in self.query) {
        NSObject *oldQuery = [self.query objectForKey:field];
        [self.query setObject:@{@"$not" : oldQuery} forKey:field];
    }
    
}


// TODO: This should use common code for the AND case.
- (KCSQuery *)queryByJoiningQuery: (KCSQuery *)query usingOperator: (KCSQueryConditional)joiningOperator
{
    NSMutableDictionary *left = self.query;
    NSMutableDictionary *right = query.query;
    KCSQuery *q = [KCSQuery query];
    
    if (joiningOperator == kKCSOr){
        NSArray *queries = [NSArray arrayWithObjects:left, right, nil];
        q.query = [NSMutableDictionary dictionaryWithObject:queries forKey:KCSConditionalStringFromEnum(kKCSOr)];
    } else {
        
        NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
        for (NSString *key in query.query) {
            [tmp setObject:[query.query objectForKey:key] forKey:key];
        }
        
        for (NSString *key in self.query) {
            [tmp setObject:[self.query objectForKey:key] forKey:key];
        }
        KCSQuery *q = [KCSQuery query];
        q.query = [[tmp mutableCopy] autorelease];
    }
    return q;
}

- (void)addSortModifier:(KCSQuerySortModifier *)modifier
{
    self.sortModifiers = [self.sortModifiers arrayByAddingObject:modifier];
}

- (void)clearSortModifiers
{
    // Assign an empty array to clear the modifiers (ie count == 0)
    self.sortModifiers = [NSArray array];
}

#pragma mark -
#pragma mark Validating Queries

+ (BOOL)validateQuery:(KCSQuery *)query
{
    return NO;
}

- (BOOL)isValidQuery
{
    return NO;
}


#pragma mark - Query Representations
- (BOOL) hasReferences
{
    return self.referenceFieldsToResolve != nil && self.referenceFieldsToResolve.count > 0;
}

- (NSString *)JSONStringRepresentation
{
    NSMutableDictionary* d = [[_query mutableCopy] autorelease];
    if ([self hasReferences]) {
        [_query enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([self.referenceFieldsToResolve containsObject:key]) {
                //use the _id to query for reference entities
                [d removeObjectForKey:key];
                [d setObject:obj forKey:[key stringByAppendingString:@"._id"]];
            }
        }];
    }
    return [d JSONRepresentation];
}

- (NSData *)UTF8JSONStringRepresentation
{
    return [self.JSONwriter dataWithObject:self.query];
}

- (NSString *)parameterStringRepresentation
{
    NSString* stringRepresentation = @"";
    // Add the Query portion of the request
    if (self.query != nil && self.query.count > 0){
        NSString* stringRep = [self JSONStringRepresentation];
        NSString* queryString = [NSString stringWithFormat:@"query=%@", [NSString stringByPercentEncodingString:stringRep]];
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:queryString];
    }
    
    // Add any sort modifiers
    if (self.sortModifiers.count > 0){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self parameterStringForSortKeys]];
    }
    
    // Add any limit modifiers
    if (self.limitModifer != nil){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self.limitModifer parameterStringRepresentation]];
    }
    
    // Add any skip modifiers
    if (self.skipModifier != nil){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self.skipModifier parameterStringRepresentation]];
    }
    if ([self hasReferences]) {
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[@"resolve=" stringByAppendingString:[self.referenceFieldsToResolve join:@","]]];
    }

    KCSLogDebug(@"query: %@",stringRepresentation);
    return stringRepresentation;
}

- (NSString*)debugDescription
{
    return [self JSONStringRepresentation];
}

#pragma mark -
#pragma mark Getting our sort keys
- (NSString *)parameterStringForSortKeys
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.sortModifiers.count];
    for (KCSQuerySortModifier *sortKey in self.sortModifiers) {
        NSNumber *direction = [NSNumber numberWithInt:sortKey.direction];
        [dict setValue:direction forKey:sortKey.field];
    }
    
    KCSLogDebug(@"Sort Keys: %@", [NSString stringWithFormat:@"sort=%@", [dict JSONRepresentation]]);
    
    return [NSString stringWithFormat:@"sort=%@", [NSString stringByPercentEncodingString:[dict JSONRepresentation]]];
    
}

#pragma mark - Equality / hashing for comparison
- (BOOL) isEqual:(id)object
{
    return [object isKindOfClass:[KCSQuery class]] && [[self JSONStringRepresentation] isEqualToString:[object JSONStringRepresentation]];
}

- (NSUInteger)hash
{
    return [[self JSONStringRepresentation] hash];
}

@end
