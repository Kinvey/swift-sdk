//
//  KCSReduceFunction.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSReduceFunction.h"

#define MAX_LENGTH 64
@interface KCSReduceFunction ()
@property (nonatomic, retain) NSString* outputField;
@property (nonatomic) BOOL buildsObjects;
@end

@implementation KCSReduceFunction

#pragma mark - Init

- (id) initWithFunction:(NSString*)function field:(NSString*)field initial:(id)initialObj
{
    self = [super init];
    if (self) {
        _jsonRepresentation = function;
        _jsonInitValue = initialObj;
        _outputField = field;
        _buildsObjects = NO;
    }
    return self;
}

#pragma mark - functions
- (NSString *)JSONStringRepresentationForFunction:(NSArray*)fields {
    return [NSString stringWithFormat:_jsonRepresentation, [self outputValueName:fields], [self outputValueName:fields]];
}

- (NSDictionary *)JSONStringRepresentationForInitialValue:(NSArray*)fields {
    return @{[self outputValueName:fields] : _jsonInitValue};
}

- (NSString*)outputValueName:(NSArray*)fields {
    
    while ([fields containsObject:_outputField] && _outputField.length < MAX_LENGTH) {
        _outputField = [NSString stringWithFormat:@"_%@", _outputField];
    }
    return _outputField;
}

#pragma mark - Helper Constructors

+ (KCSReduceFunction*) COUNT
{
    return [[KCSReduceFunction alloc] initWithFunction:@"function(doc,out){ out.%@++;}" field:@"count" initial:@0];
}

+ (KCSReduceFunction*) SUM:(NSString *)fieldToSum
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = out.%%@ + doc.%@;}", fieldToSum];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"sum" initial:@0];
}

+ (KCSReduceFunction*) MIN:(NSString *)fieldToMin
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.min(out.%%@, doc.%@);}", fieldToMin];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"min" initial:@"Infinity"];
}

+ (KCSReduceFunction*) MAX:(NSString*)fieldToMax
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.max(out.%%@, doc.%@);}", fieldToMax];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"max" initial:@"-Infinity"];  
}

+ (KCSReduceFunction*) AVERAGE:(NSString*)fieldToAverage
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ var count = (out._kcs_count == undefined) ? 0 : out._kcs_count; out.%%@ = (out.%%@ * count + doc.%@) / (count + 1); out._kcs_count = count+1;}", fieldToAverage];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"avg" initial:@0];
    
}

+ (KCSReduceFunction*) AGGREGATE
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = out.%%@.concat(doc)}"];
    KCSReduceFunction* reduceFunction = [[KCSReduceFunction alloc] initWithFunction:function field:@"objects" initial:@[]];
    reduceFunction.buildsObjects = YES;
    return reduceFunction;
}


@end
