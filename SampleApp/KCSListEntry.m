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
@synthesize imagePath=_imagePath;


- (id)init
{
    return [self initWithName:nil];
}

- (id)initWithName: (NSString *)name
{
    self = [super init];
    if (self){
        self.name = name;
    }
    return self;
}

- (BOOL)hasCustomImage
{
    return NO;
}

@end
