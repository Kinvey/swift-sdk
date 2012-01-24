//
//  KCSObjectMapper.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSObjectMapper.h"
#import "KinveyPersistable.h"
#import "KCSClient.h"
#import "KinveyEntity.h"
#import "KCSLogManager.h"

@implementation KCSSerializedObject

@synthesize isPostRequest = _isPostRequest;
@synthesize dataToSerialize = _dataToSerialize;
@synthesize objectId = _objectId;

- (id)initWithObjectId:(NSString *)objectId dataToSerialize:(NSDictionary *)dataToSerialize isPostRequest:(BOOL)isPostRequest
{
    self = [super init];
    if (self){
        _isPostRequest = isPostRequest;
        _dataToSerialize = [dataToSerialize retain];
        _objectId = [objectId retain];
    }
    return self;
}

- (void)dealloc
{
    [_dataToSerialize release];
    [_objectId release];
    [super dealloc];
}

@end

@implementation KCSObjectMapper

+ (id)populateObject:(id)object withData: (NSDictionary *)data
{
    BOOL hasFlatMap = NO;
    NSString *dictName = nil;
    
    NSDictionary *specialOptions = [[object class] kinveyObjectBuilderOptions];
    
    if (specialOptions != nil){
        dictName = [specialOptions objectForKey:KCS_DICTIONARY_NAME_KEY];
        if ([specialOptions objectForKey:KCS_USE_DICTIONARY_KEY]){
            hasFlatMap = YES;
        }
    }

    // Get the instructions for how to map the JSON to the object
    NSDictionary *hostToJsonMap = [object hostToKinveyPropertyMapping];
    
    // For every mapped item, we need to find the mapped itme in the JSON, then pull it into our object
    for (NSString *hostKey in hostToJsonMap) {
        NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];
        
        //            KCSLogDebug(@"Mapping from %@ to %@ (using value: %@)", jsonKey, hostKey, [dict valueForKey:jsonKey]);
        if ([data valueForKey:jsonKey] == nil){
            KCSLogWarning(@"Data Mismatch, unable to find value for JSON Key %@ (Host Key %@).  Object not 100%% valid.", jsonKey, hostKey);
            continue;
        }
        [object setValue:[data valueForKey:jsonKey] forKey:hostKey];
        //            KCSLogDebug(@"Copied Object: %@", copiedObject);
    }
    
    // We've processed all the known keys, let's put the rest in our "dictionary" if required
    if (hasFlatMap){
        if (dictName){
            NSArray *knownJsonProps = [hostToJsonMap allValues];
            for (NSString *property in data) {
                // Check if in known set
                if ([knownJsonProps containsObject:property]){
                    continue;
                } else {
                    // otherwise build key path and insert.
                    NSString *keyPath = [dictName stringByAppendingFormat:@".%@", property];
                    [object setValue:[data objectForKey:property] forKeyPath:keyPath];
                }
            }
        }
    }
    
    // Not necessary, just convienient
    return object;

}


+ (id)makeObjectOfType:(Class)objectClass withData: (NSDictionary *)data
{

    // Check for special options to building this class
    NSDictionary *specialOptions = [objectClass kinveyObjectBuilderOptions];
    BOOL hasDesignatedInit = NO;
    
    if (specialOptions != nil){
        if ([specialOptions objectForKey:KCS_USE_DESIGNATED_INITIALIZER_MAPPING_KEY] != nil){
            hasDesignatedInit = YES;
        }
    }

    // Actually generate the instance of the class
    id copiedObject = nil;
    if (hasDesignatedInit){
        // If we need to use a designated initializer we do so here
        copiedObject = [objectClass kinveyDesignatedInitializer];
    } else {
        // Normal path
        copiedObject = [[[objectClass alloc] init] autorelease];
    }

    return [KCSObjectMapper populateObject:copiedObject withData:data];

}

+ (KCSSerializedObject *)makeKinveyDictionaryFromObject: (id)object
{
    
    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [object hostToKinveyPropertyMapping];
    NSString *objectId = nil;
    BOOL isPostRequest = NO;
    
    NSString *key;
    for (key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        [dictionaryToMap setValue:[object valueForKey:key] forKey:jsonName];
        
        if ([jsonName isEqualToString:@"_id"]){
            objectId = [object valueForKey:key];
            if (objectId == nil){
                isPostRequest = YES;
                objectId = @""; // Set to the empty string for the document path
            } else {
                isPostRequest = NO;
            }
        }
    }
    
    // We've handled all the built-in keys, we need to just store the dict if there is one
    BOOL useDictionary = [[[[object class] kinveyObjectBuilderOptions] objectForKey:KCS_USE_DICTIONARY_KEY] boolValue];
    
    if (useDictionary){
        // Get the name of the dictionary to store
        NSString *dictionaryName = [[[object class] kinveyObjectBuilderOptions] objectForKey:KCS_DICTIONARY_NAME_KEY];

        NSDictionary *subDict = (NSDictionary *)[object valueForKey:dictionaryName];
        for (NSString *key in subDict) {
            [dictionaryToMap setObject:[subDict objectForKey:key] forKey:key];
        }
    }
    
    KCSSerializedObject *sObject = [[[KCSSerializedObject alloc] initWithObjectId:objectId dataToSerialize:dictionaryToMap isPostRequest:isPostRequest] autorelease];
    
    [dictionaryToMap release];
    return sObject;

}


@end
