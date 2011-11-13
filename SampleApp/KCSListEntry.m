//
//  KCSListEntry.m
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSListEntry.h"

@implementation KCSListEntry

@synthesize name=_name;
@synthesize image=_image;
@synthesize objectId=_id;
@synthesize itemDescription=_itemDescription;
@synthesize loadedImage=_loadedImage;
@synthesize list=_list;


- (id)init
{
    return [self initWithName:nil];
}

- (id)initWithName: (NSString *)name
{
    return [self initWithName:name withDescription:nil];
}

- (id)initWithName:(NSString *)name withDescription: (NSString *)description;
{
    self = [super init];
    if (self){
        self.name = name;
        self.itemDescription = description;
    }
    return self;
}

- (BOOL)hasCustomImage
{
    return NO;
}


- (NSDictionary*)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"_id", @"objectId",
            @"name", @"name",
            @"list", @"list",
            @"description", @"itemDescription",
            nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Object ID: %@\nName: %@\nDescription: %@\nImage: %@\n", self.objectId, self.name, self.itemDescription, self.image];
}


@end
