//
//  KCSEntityDict.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSEntityDict.h"

// Private interface
@interface KCSEntityDict ()
@property (nonatomic, retain) NSMutableDictionary *entityProperties;
@end



@implementation KCSEntityDict

@synthesize entityProperties = _entityProperties;
@synthesize objectId = _objectId;

- (id)init
{
    self = [super init];
    if (self) {
        _entityProperties = [[NSMutableDictionary alloc] init];
        _objectId = [[NSString alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_entityProperties release];
    [_objectId release];
    [super dealloc];
}

- (id)getValueForProperty: (NSString *)property
{
    return [self.entityProperties objectForKey:property];
}

- (void)setValue: (id)value forProperty:(NSString *)property
{
    [self.entityProperties setObject:value forKey:property];
}



+ (NSDictionary *)kinveyObjectBuilderOptions
{
    static NSDictionary *options = nil;
    
    if (options == nil){
        options = [[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], KCS_USE_DICTIONARY_KEY,
                    @"entityProperties", KCS_DICTIONARY_NAME_KEY, nil] retain];
    }
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    
    if (mappedDict == nil){
        mappedDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                       @"_id", @"objectId", nil] retain];
    }
    
    return mappedDict;
}


@end
