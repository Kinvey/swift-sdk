//
//  KCSEntityDict.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//

#import "KCSEntityDict.h"
#import "KCSLogManager.h"

// Private interface
@interface KCSEntityDict () 
@property (nonatomic, strong) NSMutableDictionary *entityProperties;
@end



@implementation KCSEntityDict

- (instancetype) init
{
    self = [super init];
    if (self) {
        _entityProperties = [[NSMutableDictionary alloc] init];
        _objectId = nil;
    }
    return self;
}


- (id) getValueForProperty: (NSString *)property
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
        options = @{KCS_USE_DICTIONARY_KEY : @(YES),
                     KCS_DICTIONARY_NAME_KEY : @"entityProperties"
                    };
    });
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{ @"objectId" : KCSEntityKeyId};
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

+ (id)kinveyDesignatedInitializer:(NSDictionary*)jsonDocument
{
    return [NSMutableDictionary dictionary];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    KCSLogWarning(@"%d cannot setValue for %@", self, key);
}

@end
