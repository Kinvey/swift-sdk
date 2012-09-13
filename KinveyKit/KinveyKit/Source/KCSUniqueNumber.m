//
//  KCSCounterEntity.m
//  KinveyKit
//
//  Created by Michael Katz on 9/13/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSUniqueNumber.h"

@interface KCSUniqueNumber ()
@property (nonatomic, readonly) NSString* type;
@property (nonatomic, assign, getter = valueObj, setter = setValueObj:) NSNumber* valueObj;
@end

@implementation KCSUniqueNumber
@synthesize value = _value;
@synthesize sequenceId = _sequenceId;
@synthesize metadata = _metadata;
@synthesize type = _type;

+ (KCSUniqueNumber*) defaultSequence
{
    KCSUniqueNumber* counter = [[[KCSUniqueNumber alloc] init] autorelease];
    counter.sequenceId = KCSSequenceId;
    return counter;
}

- (id)init
{
    self = [super init];
    if (self) {
        _type = [KCSSequenceType retain];
    }
    return self;
}

- (void) dealloc
{
    [_sequenceId release];
    [_type release];
    [_metadata release];
    [super dealloc];
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary* mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = [@{ @"sequenceId" : KCSEntityKeyId, @"metadata" : KCSEntityKeyMetadata, @"valueObj" : @"value", @"type" : @"_type"} retain];
    });
    return mapping;
}

- (void) reset
{
    self.value = 0;
}

- (void) setValueObj:(NSNumber *)valueObj
{
    _value = [valueObj integerValue];
}

- (NSNumber *)valueObj
{
    return @(_value);
}
@end
