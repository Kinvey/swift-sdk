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

- (id) init
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

@end
