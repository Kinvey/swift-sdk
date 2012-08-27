//
//  KCSObjectMapper.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSObjectMapper.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "KCSPropertyUtil.h"

#import "KinveyPersistable.h"
#import "KCSClient.h"
#import "KinveyEntity.h"
#import "KCSLogManager.h"
#import "KCSResource.h"
#import "KCSMetadata.h"

#import "KCSBuilders.h"

#define kKMDKey @"_kmd"
#define kACLKey @"_acl"

@interface KCSMetadata ()
- (id) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)acl;
- (NSDictionary*) aclValue;
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

- (NSString *)debugDescription
{
    return [self.dataToSerialize description];
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
            if (resources != nil && [KCSResource isResourceDictionary:value]) {
                //this is a linked resource
                [resources setValue:value forKey:hostKey];
            } else if (YES) {
                NSString* valueType = [properties valueForKey:hostKey];
                Class valClass = objc_getClass([valueType UTF8String]);
                Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
                if (builder != nil) {
                    id builtValue = [builder objectForJSONObject:value];
                    [object setValue:builtValue forKey:hostKey];
                } else {
                    [object setValue:value forKey:hostKey];
                }
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
    return [self makeObjectWithResourcesOfType:objectClass withData:data withDictionary:nil];
}

+ (id)makeObjectWithResourcesOfType:(Class)objectClass withData:(NSDictionary *)data withDictionary:(NSMutableDictionary*)resources
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
        _defaultBuilders = [@{(id)[NSDate class] : [KCSDateBuilder class],
                            (id)[NSSet class] : [KCSSetBuilder class],
                            (id)[NSMutableSet class] : [KCSMSetBuilder class],
                            (id)[NSOrderedSet class] : [KCSOrderedSetBuilder class],
                            (id)[NSMutableOrderedSet class] : [KCSMOrderedSetBuilder class],
                            (id)[NSMutableAttributedString class] : [KCSMAttributedStringBuilder class],
                            (id)[NSAttributedString class] : [KCSAttributedStringBuilder class]} retain];
}
}

Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass);
Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass)
{
    NSDictionary* options = builderOptions(object);
    NSDictionary* builders = [options objectForKey:kCS_DICTIONARY_DATATYPE_BUILDER];
    Class<KCSDataTypeBuilder> builderClass = ifNotNil(builders, [builders objectForKey:valClass]);
    if (builderClass == nil) {
        NSDictionary* d = defaultBuilders();
        builderClass = [d objectForKey:valClass];
    }
    return ifNotNil(builderClass, builderClass);
}

+ (KCSSerializedObject*) makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName withProps:(BOOL)withProps
{
    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [object hostToKinveyPropertyMapping];
    NSString *objectId = nil;
    BOOL isPostRequest = NO;
    
    NSMutableArray* resourcesToSave = withProps ? [NSMutableArray array] : nil;
    
    for (NSString* key in kinveyMapping) {
        NSString *jsonName = [kinveyMapping valueForKey:key];
        id value = [object valueForKey:key];
        
        //get the id
        if ([jsonName isEqualToString:KCSEntityKeyId]){
            if (value == nil){
                isPostRequest = YES;
                objectId = @""; // Set to the empty string for the document path
            } else {
                isPostRequest = NO;
                objectId = value;
            }
        }
        
        if (value == nil) {
            //don't map nils
            continue;
        }
        
        //serialize the fields to a dictionary
        if ([jsonName isEqualToString:KCSEntityKeyMetadata]) {
            //hijack metadata
            [dictionaryToMap setValue:[(KCSMetadata*)value aclValue] forKey:kACLKey];
        } else {
            if (withProps == YES && isResourceType(value) == YES) {
                NSString* objname = [object kinveyObjectId];//set.count == 0 ? nil: [object valueForKey:[set anyObject]];
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
            } else {
                Class valClass = [value classForCoder];
                Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
                if (builder != nil) {
                    id jsonType = [builder JSONCompatabileValueForObject:value];
                    [dictionaryToMap setValue:jsonType forKey:jsonName];
                } else {
                    //TODO handle complex types
                    //don't need to look at type, just save
                    [dictionaryToMap setValue:value forKey:jsonName];
                }
            }
        } // end test object name
    } // end for key in kinveyMapping
    
    // We've handled all the built-in keys, we need to just store the dict if there is one
    BOOL useDictionary = [[builderOptions(object) objectForKey:KCS_USE_DICTIONARY_KEY] boolValue];
    
    if (useDictionary == YES) {
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

+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:collectionName withProps:YES];
}

+ (KCSSerializedObject *)makeKinveyDictionaryFromObject: (id)object
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:nil withProps:NO];
}

@end
