//
//  KCSList.m
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSList.h"

@interface KCSList ()

@property (retain) NSDictionary *mappingDictionary;

@end


@implementation KCSList

@synthesize entries=_entries;
@synthesize name=_name;
@synthesize listImage=_listImage;
@synthesize image=_image;
@synthesize mappingDictionary=_mappingDictionary;
@synthesize listId=_listId;

- (id)initWithName: (NSString *)name withList: (NSMutableArray *)list
{
    self = [super init];
    if (self){
        self.entries = list;
        self.name = name;
        self.listImage = nil;
        self.image = nil;
        
        self.mappingDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"_id", @"listId",
                                  @"name", @"name",
                                  @"image", @"image",
                                  nil];
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

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return self.mappingDictionary;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"List ID: %@\nName: %@\nImage: %@\n", self.listId, self.name, self.image];
}



@end
