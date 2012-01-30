//
//  KCSQuery.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    // NO OP
    kKCSNOOP = 0,
    
    // Basic operators
    kKCSLessThan = 16,
    kKCSLessThanOrEqual = 17,
    kKCSGreaterThan = 18,
    kKCSGreaterThanOrEqual = 19,
    kKCSNotEqual = 20,
    
    // Geo Queries
    kKCSNearSphere = 1024,
    kKCSWithinBox = 1025,
    kKCSWithinCenterSphere = 1026,
    kKCSWithinPolygon = 1027,
    kKCSNotIn = 1028,
    kKCSIn = 1029,
    

    // Joining Operators
    kKCSOr = 4097,
    kKCSAnd = 4098,

    
    // Array Operators
    kKCSAll = 8192,
    kKCSSize = 8193,

    // Arbitrary Operators
    kKCSWhere = 16384,
    
    // Internal Operators
    kKCSWithin = 17000,
    kKCSMulti = 17001
    
} KCSQueryConditional;

// DO NOT CHANGE THE VALUES IN THIS ENUM.  They're meaningful to the implementation of this class
typedef enum {
    kKCSAscending = 0,
    kKCSDescending = 2
} KCSSortDirection;

@interface KCSQuerySortModifier : NSObject
@property (nonatomic, copy) NSString *field;
@property (nonatomic, assign) KCSSortDirection direction;

- (id)initWithField: (NSString *)field inDirection: (KCSSortDirection)direction;

@end

@interface KCSQueryLimitModifier : NSObject
@property (nonatomic, assign) NSInteger limit;

- (id)initWithLimit: (NSInteger)limit;
- (NSString *)parameterStringRepresentation;

@end

@interface KCSQuerySkipModifier : NSObject
@property (nonatomic, assign) NSInteger count;

- (id)initWithcount: (NSInteger)count;
- (NSString *)parameterStringRepresentation;

@end



@interface KCSQuery : NSObject

///---------------------------------------------------------------------------------------
/// @name Creating Queries
///---------------------------------------------------------------------------------------
+ (KCSQuery *)queryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value;
+ (KCSQuery *)queryOnField:(NSString *)field withExactMatchForValue: (NSObject *)value; // Accepts Regular Expressions
+ (KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ... NS_REQUIRES_NIL_TERMINATION;
+ (KCSQuery *)queryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ... NS_REQUIRES_NIL_TERMINATION;
+ (KCSQuery *)queryNegatingQuery:(KCSQuery *)query;
+ (KCSQuery *)queryForNilValueInField: (NSString *)field;
+ (KCSQuery *)query;

///---------------------------------------------------------------------------------------
/// @name Modifying Queries
///---------------------------------------------------------------------------------------
- (void)addQuery: (KCSQuery *)query;
- (void)addQueryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value;
- (void)addQueryOnField:(NSString *)field withExactMatchForValue: (NSObject *)value; // Accepts Regular Expressions
- (void)addQueryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ... NS_REQUIRES_NIL_TERMINATION;
- (void)addQueryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ... NS_REQUIRES_NIL_TERMINATION;
- (void)addQueryNegatingQuery:(KCSQuery *)query;
- (void)clear;
- (void)negateQuery;

- (KCSQuery *)queryByJoiningQuery: (KCSQuery *)query usingOperator: (KCSQueryConditional)joiningOperator;




///---------------------------------------------------------------------------------------
/// @name Validating Queries
///---------------------------------------------------------------------------------------
+ (BOOL)validateQuery:(KCSQuery *)query;
- (BOOL)isValidQuery;

///---------------------------------------------------------------------------------------
/// @name Query Representations
///---------------------------------------------------------------------------------------
@property (nonatomic, readonly, copy) NSMutableDictionary *query;

- (NSString *)JSONStringRepresentation;
- (NSData *)UTF8JSONStringRepresentation;
- (NSString *)parameterStringRepresentation;
- (NSString *)parameterStringForSortKeys;


///---------------------------------------------------------------------------------------
/// @name Modifying Queries
///---------------------------------------------------------------------------------------
@property (nonatomic, retain) KCSQueryLimitModifier *limitModifer;
@property (nonatomic, retain) KCSQuerySkipModifier *skipModifier;
@property (nonatomic, retain) NSArray *sortModifiers;

- (void)addSortModifiersObject:(KCSQuerySortModifier *)modifier;


@end
