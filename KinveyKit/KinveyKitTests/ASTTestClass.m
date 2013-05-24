//
//  ASTTestClass.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "ASTTestClass.h"
#import <KinveyKit/KinveyKit.h>

@implementation ASTTestClass

- (instancetype) init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
    }
    return self;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"objId" : KCSEntityKeyId,
                @"meta" : KCSEntityKeyMetadata,
                @"objCount" : @"objCount",
                @"objDescription" : @"objDescription",
                @"date" : @"date"};
}

- (NSUInteger)hash
{
    return [_objId hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (object == [NSNull null]) return NO;
    ASTTestClass* o = object;
    BOOL classSame = [[self class] isEqual:[object class]];
    BOOL objSame = (_objId == nil || o.objId == nil) ? [super isEqual:object] : [_objId isEqual:o.objId];
    return  classSame && objSame;
}

@end
