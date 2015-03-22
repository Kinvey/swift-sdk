//
//  KCSMutableSortedDictionary.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-22.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSMutableSortedDictionary.h"

@interface KCSMutableSortedDictionary ()

@property (nonatomic, strong) NSMutableDictionary* dictionary;
@property (nonatomic, strong) NSMutableOrderedSet* keys;

@end

@implementation KCSMutableSortedDictionary

-(instancetype)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        self.dictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
        self.keys = [NSMutableOrderedSet orderedSetWithCapacity:numItems];
    }
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)otherDictionary
{
    self = [super initWithDictionary:otherDictionary];
    return self;
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    [self.dictionary setObject:anObject forKey:aKey];
    [self.keys addObject:aKey];
}

-(NSUInteger)count
{
    return self.dictionary.count;
}

-(id)objectForKey:(id)aKey
{
    return [self.dictionary objectForKey:aKey];
}

-(NSEnumerator *)keyEnumerator
{
    return self.keys.objectEnumerator;
}

@end
