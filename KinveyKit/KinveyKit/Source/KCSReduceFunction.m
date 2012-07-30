//
//  KCSReduceFunction.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSReduceFunction.h"

#define MAX_LENGTH 64
@interface KCSReduceFunction ()
@property (nonatomic, retain) NSString* outputField;
@end

@implementation KCSReduceFunction
@synthesize outputField = _outputField;

#pragma mark - Init

- (id) initWithFunction:(NSString*)function field:(NSString*)field initial:(id)initialObj
{
    self = [super init];
    if (self) {
        _jsonRepresentation = [function retain];
        _jsonInitValue = [initialObj retain];
        _outputField = [field retain];
    }
    return self;
}

- (void) dealloc
{
    [_jsonRepresentation release];
    [_jsonInitValue release];
    [_outputField release];
    [super dealloc];
}

#pragma mark - functions
- (NSString *)JSONStringRepresentationForFunction:(NSArray*)fields {
    return [NSString stringWithFormat:_jsonRepresentation, [self outputValueName:fields], [self outputValueName:fields]];
}

- (NSDictionary *)JSONStringRepresentationForInitialValue:(NSArray*)fields {
    return [NSDictionary dictionaryWithObjectsAndKeys:_jsonInitValue, [self outputValueName:fields], nil];
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
    return [[[KCSReduceFunction alloc] initWithFunction:@"function(doc,out){ out.%@++;}" field:@"count" initial:[NSNumber numberWithInt:0]] autorelease];
}

+ (KCSReduceFunction*) SUM:(NSString *)fieldToSum
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = out.%%@ + doc.%@;}", fieldToSum];
    return [[[KCSReduceFunction alloc] initWithFunction:function field:@"sum" initial:[NSNumber numberWithInt:0]] autorelease];
}

+ (KCSReduceFunction*) MIN:(NSString *)fieldToMin
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.min(out.%%@, doc.%@);}", fieldToMin];
    return [[[KCSReduceFunction alloc] initWithFunction:function field:@"min" initial:@"Infinity"] autorelease];
}

+ (KCSReduceFunction*) MAX:(NSString*)fieldToMax
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.max(out.%%@, doc.%@);}", fieldToMax];
    return [[[KCSReduceFunction alloc] initWithFunction:function field:@"max" initial:@"-Infinity"] autorelease];  
}

+ (KCSReduceFunction*) AVERAGE:(NSString*)fieldToAverage
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ var count = (out._kcs_count == undefined) ? 0 : out._kcs_count; out.%%@ = (out.%%@ * count + doc.%@) / (count + 1); out._kcs_count = count+1;}", fieldToAverage];
    return [[[KCSReduceFunction alloc] initWithFunction:function field:@"avg" initial:[NSNumber numberWithInt:0]] autorelease];  
    
}

@end
