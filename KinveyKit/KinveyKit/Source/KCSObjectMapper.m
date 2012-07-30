//
//  KCSObjectMapper.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSObjectMapper.h"

#import <UIKit/UIKit.h>
#import "KCSPropertyUtil.h"

#import "KinveyPersistable.h"
#import "KCSClient.h"
#import "KinveyEntity.h"
#import "KCSLogManager.h"
#import "KCSResource.h"
#import "KCSMetadata.h"

#define kKMDKey @"_kmd"
#define kACLKey @"_acl"

@interface KCSMetadata ()
- (id) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)acl;
- (NSDictionary*) aclValue;
@end

@protocol KCSDataTypeBuilder <NSObject>

+ (id) JSONCompatabileValueForObject:(id)object;
+ (id) objectForJSONObject:(id)object;

@end
@interface DateBuilder : NSObject <KCSDataTypeBuilder>
@end
#import "NSDate+ISO8601.h"
@implementation DateBuilder
+ (id) JSONCompatabileValueForObject:(id)object
{
    return [NSString stringWithFormat:@"ISODate(%c%@%c)", '"', [object stringWithISO8601Encoding], '"'];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSDate class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        NSString *tmp = [(NSString *)object stringByReplacingOccurrencesOfString:@"ISODate(\"" withString:@""];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\")" withString:@""];
        NSDate *date = [NSDate dateFromISO8601EncodedString:tmp];
        return date;
    }
    return [NSNull null];
}

@end

NSDictionary* builderOptions(id object);
NSDictionary* builderOptions(id object) 
{
    return  [[object class] kinveyObjectBuilderOptions];
}

@implementation KCSSerializedObject

@synthesize isPostRequest = _isPostRequest;
@synthesize dataToSerialize = _dataToSerialize;
@synthesize objectId = _objectId;
@synthesize resourcesToSave = _resourcesToSave;

- (id)initWithObjectId:(NSString *)objectId dataToSerialize:(NSDictionary *)dataToSerialize isPostRequest:(BOOL)isPostRequest resources:(NSArray*)resources
{
    self = [super init];
    if (self){
        _isPostRequest = isPostRequest;
        _dataToSerialize = [dataToSerialize retain];
        _objectId = [objectId retain];
        _resourcesToSave = [resources retain];
    }
    return self;
}

- (void)dealloc
{
    [_resourcesToSave release];
    [_dataToSerialize release];
    [_objectId release];
    [super dealloc];
}

@end

@implementation KCSObjectMapper
+ (id)populateObject:(id)object withData: (NSDictionary *)data {
    return [self populateObjectWithLinkedResources:object withData:data resourceDictionary:nil];
}

+ (id)populateObjectWithLinkedResources:(id)object withData: (NSDictionary *)data resourceDictionary:(NSMutableDictionary*)resources
{
    BOOL hasFlatMap = NO;
    NSString *dictName = nil;
    
    NSDictionary *specialOptions = builderOptions(object);
    
    if (specialOptions != nil){
        dictName = [specialOptions objectForKey:KCS_DICTIONARY_NAME_KEY];
        if ([specialOptions objectForKey:KCS_USE_DICTIONARY_KEY]){
            hasFlatMap = YES;
        }
    }
    
    // Get the instructions for how to map the JSON to the object
    NSDictionary *hostToJsonMap = [object hostToKinveyPropertyMapping];
    
    NSDictionary* properties = [KCSPropertyUtil classPropsFor:[object class]];
    
    // For every mapped item, we need to find the mapped item in the JSON, then pull it into our object
    for (NSString *hostKey in hostToJsonMap) {
        NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];
        
        //            KCSLogDebug(@"Mapping from %@ to %@ (using value: %@)", jsonKey, hostKey, [dict valueForKey:jsonKey]);
        
        id value = nil;
        if ([jsonKey isEqualToString:KCSEntityKeyMetadata]) {
            NSDictionary* kmd = [data objectForKey:kKMDKey];
            NSDictionary* acl = [data objectForKey:kACLKey];
            KCSMetadata* metadata = [[[KCSMetadata alloc] initWithKMD:kmd acl:acl] autorelease];
            value = metadata;
        } else {        
            value = [data valueForKey:jsonKey];
        }
        
        if (value == nil){
            KCSLogWarning(@"Data Mismatch, unable to find value for JSON Key %@ (Host Key %@).  Object not 100%% valid.", jsonKey, hostKey);
            continue;
        } else {
            NSString* valueType = [properties valueForKey:hostKey];
            if (resources != nil && [KCSResource isResourceDictionary:value]) {
                //this is a linked resource
                [resources setValue:value forKey:hostKey];
            } else if (resources != nil && isComplexJSONType(object, valueType) == YES) {
                id complexObject = [builderForComplexType(object, valueType) objectForJSONObject:value];
                [object setValue:complexObject forKey:hostKey];
            } else {
                [object setValue:value forKey:hostKey];
            }
            //            KCSLogDebug(@"Copied Object: %@", copiedObject);
        }
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
    return [self makeObjectWithResorucesOfType:objectClass withData:data withDictionary:nil];
}

+ (id)makeObjectWithResorucesOfType:(Class)objectClass withData:(NSDictionary *)data withDictionary:(NSMutableDictionary*)resources
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
    
    return [KCSObjectMapper populateObjectWithLinkedResources:copiedObject withData:data resourceDictionary:resources];
}

//TODO: builder options
BOOL isResourceType(id object);
BOOL isResourceType(id object)
{
    return [object isKindOfClass:[UIImage class]];
}

NSString* extensionForResource(id object);
NSString* extensionForResource(id object)
{
    if ([object isKindOfClass:[UIImage class]]) {
        return @".png";
    } 
    return @"";
}

static NSDictionary* _defaultBuilders;
NSDictionary* defaultBuilders();
NSDictionary* defaultBuilders()
{
    return _defaultBuilders;
}

+ (void)initialize
{
    if (!_defaultBuilders) {
        _defaultBuilders = [[NSDictionary dictionaryWithObjectsAndKeys:[DateBuilder class], NSStringFromClass([NSDate class]), nil] retain];
    }
}


Class<KCSDataTypeBuilder> builderForComplexType(id object, NSString* valueType);
Class<KCSDataTypeBuilder> builderForComplexType(id object, NSString* valueType)
{
    NSDictionary* options = builderOptions(object);
    NSDictionary* builders = [options objectForKey:kCS_DICTIONARY_DATATYPE_BUILDER];
    Class<KCSDataTypeBuilder> builderClass = ifNotNil(builders, [builders objectForKey:valueType]);
    if (builderClass == nil) {
        NSDictionary* d = defaultBuilders();
        builderClass = [d valueForKey:valueType];
    }
    return ifNotNil(builderClass, builderClass);
}

BOOL isComplexJSONType(id object, NSString* valueType);
BOOL isComplexJSONType(id object, NSString* valueType)
{
    return builderForComplexType(object, valueType) != nil;
}

+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName
{
    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSMutableArray *resourcesToSave = [NSMutableArray array];
    NSDictionary *kinveyMapping = [object hostToKinveyPropertyMapping];
    NSString *objectId = nil;
    BOOL isPostRequest = NO;
    
    
    NSDictionary* properties = [KCSPropertyUtil classPropsFor:[object class]];
    
    NSString *key;
    for (key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        id value = [object valueForKey:key];
        
        if ([jsonName isEqualToString:KCSEntityKeyMetadata]) {
            KCSMetadata* metadata = value;
            if (value != nil) {
                [dictionaryToMap setValue:[metadata aclValue] forKey:kACLKey];
            }
        } else {
            if (value != nil) {
                NSString* valueType = [properties valueForKey:key];
                if (isResourceType(value) == YES) { 
                    NSSet* set = [kinveyMapping keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        return [obj isEqualToString:@"_id"];
                    }];
                    NSString* objname = set.count == 0 ? nil: [object valueForKey:[set anyObject]];
                    if (objname == nil) {
                        CFUUIDRef uuid = CFUUIDCreate(NULL);
                        
                        if (uuid){
                            objname = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
                            CFRelease(uuid);
                        }
                    }
                    NSString* filename = [NSString stringWithFormat:@"%@-%@-%@%@", collectionName, objname, key, extensionForResource(value)];
                    KCSResource* resourceWrapper = [[KCSResource alloc] initWithResource:value name:filename];
                    [resourcesToSave addObject:resourceWrapper];
                    [dictionaryToMap setValue:[resourceWrapper dictionaryRepresentation] forKey:jsonName];
                    [resourceWrapper release];
                } else if (isComplexJSONType(object, valueType) == YES) {
                    id jsonType = [builderForComplexType(object, valueType) JSONCompatabileValueForObject:value];
                    [dictionaryToMap setValue:jsonType forKey:jsonName];
                }
                else {
                    [dictionaryToMap setValue:value forKey:jsonName];
                }
            }
        }
        
        if ([jsonName isEqualToString:KCSEntityKeyId]){
            objectId = value;
            if (objectId == nil){
                isPostRequest = YES;
                objectId = @""; // Set to the empty string for the document path
            } else {
                isPostRequest = NO;
            }
        }
    }
    
    // We've handled all the built-in keys, we need to just store the dict if there is one
    BOOL useDictionary = [[builderOptions(object) objectForKey:KCS_USE_DICTIONARY_KEY] boolValue];
    
    if (useDictionary){
        // Get the name of the dictionary to store
        NSString *dictionaryName = [builderOptions(object) objectForKey:KCS_DICTIONARY_NAME_KEY];
        
        NSDictionary *subDict = (NSDictionary *)[object valueForKey:dictionaryName];
        for (NSString *key in subDict) {
            [dictionaryToMap setObject:[subDict objectForKey:key] forKey:key];
        }
    }
    
    KCSSerializedObject *sObject = [[[KCSSerializedObject alloc] initWithObjectId:objectId dataToSerialize:dictionaryToMap isPostRequest:isPostRequest resources:resourcesToSave] autorelease];
    
    [dictionaryToMap release];
    return sObject;
    
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
        
        if ([jsonName isEqualToString:KCSEntityKeyMetadata]) {
            KCSMetadata* metadata = [object valueForKey:key];
            if (metadata != nil) {
                [dictionaryToMap setValue:[metadata aclValue] forKey:kACLKey];
            }
        } else {
            [dictionaryToMap setValue:[object valueForKey:key] forKey:jsonName];
        }
        
        if ([jsonName isEqualToString:KCSEntityKeyId]){
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
    BOOL useDictionary = [[builderOptions(object) objectForKey:KCS_USE_DICTIONARY_KEY] boolValue];
    
    if (useDictionary){
        // Get the name of the dictionary to store
        NSString *dictionaryName = [builderOptions(object) objectForKey:KCS_DICTIONARY_NAME_KEY];
        
        NSDictionary *subDict = (NSDictionary *)[object valueForKey:dictionaryName];
        for (NSString *key in subDict) {
            [dictionaryToMap setObject:[subDict objectForKey:key] forKey:key];
        }
    }
    
    KCSSerializedObject *sObject = [[[KCSSerializedObject alloc] initWithObjectId:objectId dataToSerialize:dictionaryToMap isPostRequest:isPostRequest resources:nil] autorelease];
    
    [dictionaryToMap release];
    return sObject;    
}



@end
