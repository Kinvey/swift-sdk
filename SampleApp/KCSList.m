//
//  KCSList.m
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSList.h"

@implementation KCSList


@synthesize entries=_entries;
@synthesize name=_name;
@synthesize listImage=_listImage;

- (id)initWithName: (NSString *)name withList: (NSMutableArray *)list
{
    self = [super init];
    if (self){
        self.entries = list;
        self.name = name;
        self.listImage = nil;
    }
    
    return self;
}


- (id)init
{
    return [self initWithName:nil withList:nil];
}

- (BOOL)hasCustomImage
{
    return NO;
}


- (id)objectAtIndex: (NSUInteger)index
{
    return [self.entries objectAtIndex:index];
}

- (NSUInteger)count
{
    return self.entries.count;
}


@end
