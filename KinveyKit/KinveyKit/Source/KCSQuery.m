//
//  KCSQuery.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSQuery.h"
#import "KCSLogManager.h"
#import "KCS_SBJson.h"
#import "NSString+KinveyAdditions.h"
#import "NSArray+KinveyAdditions.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSHiddenMethods.h"
#import "KCSBuilders.h"
#import "NSMutableDictionary+KinveyAdditions.h"
#import "KCSMetadata.h"
#import "NSDate+ISO8601.h"

//http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24type
typedef enum KCSQueryType : NSUInteger {
    KCSQueryTypeNull = 10
} KCSQueryType;

#pragma mark -
#pragma mark KCSQuerySortModifier
@implementation KCSQuerySortModifier

- (id)initWithField:(NSString *)field inDirection:(KCSSortDirection)direction
{
    self = [super init];
    if (self) {
        _field = field;
        _direction = direction;
    }
    return self;
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

NSString * KCSConditionalStringFromEnum(KCSQueryConditional conditional)
{
    static NSDictionary *KCSOperationStringLookup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KCSOperationStringLookup = @{
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
        @(kKCSAnd)   : @"$and",
        @(kKCSNotIn) : @"$nin",
        
        // Array Operators
        @(kKCSAll)  : @"$all",
        @(kKCSSize) : @"$size",
        
        // Arbitrary Operators
        @(kKCSWhere) : @"$where",
        
        // Internal Operators
        @(kKCSWithin)  : @"$within",
        @(kKCSOptions) : @"$options",
        @(kKCSExists) : @"$exists",
        @(kKCSType) : @"$type",
        };
    });

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
        {
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
            ///// For right now Kinvey has _geoloc as a free indexed property, if the user is using a geoquery now
            if ([fieldname isEqualToString:KCSEntityKeyGeolocation] == NO) {
                //not geoloc
                NSString* reason = [NSString stringWithFormat:@"Attempting to geo-query field '%@'. Geo-location queries can only be performed on the field 'KCSEntityKeyGeolocation'.",fieldname];
                @throw [NSException exceptionWithName:@"InvalidQuery" reason:reason userInfo:nil];
            }
            query = @{KCSEntityKeyGeolocation : geoQ};
            ////
            //////////// HACK //////////////
        }
            break;
            
            // Interior array ops
        case kKCSIn:
        case kKCSNotIn:
        {
            if (fieldname == nil || queries == nil){
                return nil;
            }
            if (queries.count >0 && [[queries objectAtIndex:0] isKindOfClass:[NSArray class]]) {
                queries = [queries objectAtIndex:0];
            }
            NSDictionary *innerQ = @{opName : queries};
            query = @{fieldname : innerQ};
        }
            break;
            // Exterior array ops
        case kKCSOr:
        case kKCSAnd:
            
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
            query = @{ fieldname : queries[0]};
            break;
            
        case kKCSLessThan:
        case kKCSLessThanOrEqual:
        case kKCSGreaterThan:
        case kKCSGreaterThanOrEqual:
        case kKCSNotEqual:
        case kKCSRegex:
        case kKCSMulti:
        case kKCSExists:
        case kKCSType:
            
            if (fieldname == nil){
                // Error
                return nil;
            }
            
            if (!useQueriesForOps){
                if (op == kKCSNOOP || queries == nil || queries.count > 1){
                    // Error
                    return nil;
                }
                
                query = @{ fieldname : @{ opName : queries[0]} };
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
        _query = [NSMutableDictionary dictionary];
        _sortModifiers = @[];
        _referenceFieldsToResolve = @[];
    }
    return self;
}

- (void)dealloc
{
    _limitModifer = nil;
    _skipModifier = nil;
    _sortModifiers = nil;
    _JSONwriter = nil;
    _query = nil;
}

- (void)setQuery:(NSMutableDictionary *)query
{
    if (_query == query){
        return;
    }
    _query = [query mutableCopy];
}

+ (id) valueOrKCSPersistableId:(NSObject*) value field:(NSString*)field
{
    if (([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSNull class]]) == NO) {
        //there's no test to determine if an object has an id since there's a NSObject category
        @try {
            if ([field isEqualToString:KCSMetadataFieldLastModifiedTime] && [value isKindOfClass:[NSDate class]]) {
                value = [(NSDate*)value stringWithISO8601Encoding];
            } else {
                NSDictionary* builders = defaultBuilders();
                Class<KCSDataTypeBuilder> builderClass = [builders objectForKey:[value classForCoder]];
                if (builderClass) {
                    value = [builderClass JSONCompatabileValueForObject:value];
                } else {
                    value = [value kinveyObjectId];
                }
            }
        }
        @catch (NSException *exception) {
            // do nothing in this case
        }
    }
    if ([value isKindOfClass:[NSArray class]]) {
        //handle arrays of objects
        NSMutableArray* mArray = [value mutableCopy];
        for (NSObject* obj in [value copy]) {
            [mArray removeObject:obj];
            [mArray addObject:[self valueOrKCSPersistableId:obj field:field]];
        }
        value = mArray;
    }
    return value;
}

#pragma mark - Creating Queries
+ (KCSQuery *) queryOnField:(NSString*)field withRegex:(id)expression options:(KCSRegexpQueryOptions)options
{
    if ([expression isKindOfClass:[NSRegularExpression class]]) {
        expression = [expression pattern];
    }
    
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

+ (KCSQuery *)queryOnField:(NSString*)field withRegex:(id)expression
{
    NSUInteger options = kKCSRegexepDefault;
    if ([expression isKindOfClass:[NSRegularExpression class]]) {
        options = [(NSRegularExpression*)expression options];
        expression = [(NSRegularExpression*)expression pattern];
    }
    return [self queryOnField:field withRegex:expression options:options];
    
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value
{
    KCSQuery *query = [KCSQuery query];
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
    query.query = [[self queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO] mutableCopy];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field withExactMatchForValue:(NSObject *)value
{
    if ([value isEqual:[NSNull null]]) {
        //for the special case using 'null' in mongo is not exist or null; but since this is an exact value test, we are hijacking and returing the matches `null` query
        return [KCSQuery queryOnField:field usingConditional:kKCSType forValue:@(KCSQueryTypeNull)];
    }
    
    KCSQuery *query = [self query];
    
    value = [self valueOrKCSPersistableId:value field:field];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[value] useQueriesForOps:NO] mutableCopy];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ...
{
    NSMutableArray *args = [NSMutableArray array];
    va_list items;
    va_start(items, firstConditional);
    
    KCSQueryConditional currentCondition = firstConditional;
    
    while (currentCondition) {
        NSObject *currentQuery = va_arg(items, id);
        NSDictionary *pair = @{ @"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
        //do it this way b/c for last condition currentCondition == 0 and the next one will be undefined
        currentCondition = va_arg(items, KCSQueryConditional);
    }
    va_end(items);
    
    KCSQuery *query = [self query];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES] mutableCopy];
    
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
    
    KCSQuery *query = [self query];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:nil operation:joiningOperator forQueries:queries useQueriesForOps:NO] mutableCopy];
    
    return query;
    
    
}

BOOL kcsIsOperator(NSString* queryField)
{
    return [queryField hasPrefix:@"$"];
}

+ (NSMutableDictionary*) negateQuery:(KCSQuery*)query
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // We need to take each key in query and replace the value with a dictionary containing the key $not and the old value
    for (NSString *field in query.query) {
        NSObject *oldQuery = [query.query objectForKey:field];
        if ([oldQuery isKindOfClass:[NSDictionary class]] == NO) {
            NSException* myException = [NSException exceptionWithName:@"InvalidArgument" reason:@"Cannot negate field/value type queries. Use conditional query with 'kKCSNotEqual' instead." userInfo:nil];
            @throw myException;
        }
        
        [dict setObject:@{@"$not" : oldQuery} forKey:field];
    }
    return dict;
}

+ (KCSQuery *)queryNegatingQuery:(KCSQuery *)query
{
    KCSQuery *q = [self query];
    q.query = [self negateQuery:query];
    
    return q;
}

+ (KCSQuery *)queryForNilValueInField: (NSString *)field
{
    return [self queryForEmptyValueInField:field];
}

+ (KCSQuery*) queryForEmptyValueInField:(NSString*)field
{
    return [self queryOnField:field usingConditional:kKCSExists forValue:@(NO)];
}

+ (KCSQuery*) queryForEmptyOrNullValueInField:(NSString*)field
{
    KCSQuery *query = [self query];
    query.query = [[self queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[[NSNull null]] useQueriesForOps:NO] mutableCopy];
    return query;
}

+ (KCSQuery *)query
{
    KCSQuery *query = [[self alloc] init];
    return query;
}

+ (KCSQuery*) queryWithQuery:(KCSQuery *)query
{
    KCSQuery* newQuery = [self query];
    newQuery.query = query.query;

    //limit
    KCSQueryLimitModifier* oldLimit = query.limitModifer;
    if (oldLimit != nil) {
        newQuery.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:oldLimit.limit];
    }
    
    //skip
    KCSQuerySkipModifier* oldSKip = query.skipModifier;
    if (oldSKip != nil) {
        newQuery.skipModifier = [[KCSQuerySkipModifier alloc] initWithcount:oldSKip.count];
    }
    
    //sort
    NSArray* sorts = query.sortModifiers;
    if (sorts != nil && sorts.count > 0) {
        NSMutableArray* newSorts = [NSMutableArray arrayWithCapacity:sorts.count];
        for (KCSQuerySortModifier* s in sorts) {
            [newSorts addObject:[[KCSQuerySortModifier alloc] initWithField:s.field inDirection:s.direction]];
        }
        newQuery.sortModifiers = newSorts;
    }
    
    return newQuery;
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
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO];
    
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field withExactMatchForValue: (NSObject *)value
{
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
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
    NSMutableDictionary* d = [KCSQuery negateQuery:query];
    [self.query addEntriesFromDictionary:d];
}

- (void)clear
{
    [self.query removeAllObjects];
}


- (void)negateQuery
{
    self.query = [KCSQuery negateQuery:self];
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
        q.query = [tmp mutableCopy];
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
    NSMutableDictionary* d = [_query mutableCopy];
    if ([self hasReferences]) {
        [_query append:@"._id" ontoKeySet:self.referenceFieldsToResolve recursive:YES];
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
