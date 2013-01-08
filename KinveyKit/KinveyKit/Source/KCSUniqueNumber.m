//
//  KCSCounterEntity.m
//  KinveyKit
//
//  Created by Michael Katz on 9/13/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSUniqueNumber.h"

@interface KCSUniqueNumber ()
@property (nonatomic, readonly) NSString* type;
@property (nonatomic, assign, getter = valueObj, setter = setValueObj:) NSNumber* valueObj;
@end

@implementation KCSUniqueNumber

+ (KCSUniqueNumber*) defaultSequence
{
    KCSUniqueNumber* counter = [[KCSUniqueNumber alloc] init];
    counter.sequenceId = KCSSequenceId;
    return counter;
}

- (id)init
{
    self = [super init];
    if (self) {
        _type = KCSSequenceType;
    }
    return self;
}


- (NSDictionary *)hostToKinveyPropertyMapping
{
    return  @{ @"sequenceId" : KCSEntityKeyId, @"metadata" : KCSEntityKeyMetadata, @"valueObj" : @"value", @"type" : @"_type"};
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
