//
//  KNVQuery.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVQuery.h"

@implementation KNVQuery

-(instancetype)initWithPredicate:(NSPredicate*)predicate
                 sortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors
{
    self = [super init];
    if (self) {
        self.predicate = predicate;
        self.sortDescriptors = sortDescriptors;
    }
    return self;
}

@end
