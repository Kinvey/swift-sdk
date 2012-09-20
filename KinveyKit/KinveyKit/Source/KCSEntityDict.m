//
//  KCSEntityDict.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KCSEntityDict.h"
#import "KCSLogManager.h"

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
        _objectId = nil;
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [@{KCS_USE_DICTIONARY_KEY : @(YES),
                     KCS_DICTIONARY_NAME_KEY : @"entityProperties"
                    } retain];
    });
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    
    if (mappedDict == nil){
        mappedDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                       KCSEntityKeyId, @"objectId", nil] retain];
    }
    
    return mappedDict;
}

- (NSString *)debugDescription
{
    return [self.entityProperties description];
}
@end

@implementation NSDictionary (KCSEntityDict)

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjects:[self allKeys] forKeys:[self allKeys]];
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_USE_DESIGNATED_INITIALIZER_MAPPING_KEY : @(YES), KCS_IS_DYNAMIC_ENTITY: @(YES)};
}

+ (id)kinveyDesignatedInitializer
{
    return [NSMutableDictionary dictionary];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    KCSLogWarning(@"%d cannot setValue for %@", self, key);
}

@end
