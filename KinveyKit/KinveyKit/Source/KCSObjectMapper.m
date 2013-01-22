//
//  KCSObjectMapper.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSObjectMapper.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

//TODO: remove core location as dependency injection
#import <CoreLocation/CoreLocation.h>

#import "KCSPropertyUtil.h"

#import "KinveyPersistable.h"
#import "KCSClient.h"
#import "KinveyEntity.h"
#import "KCSLogManager.h"
#import "KCSResource.h"
#import "KCSMetadata.h"

#import "KCSBuilders.h"

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"

#define kKMDKey @"_kmd"
#define kACLKey @"_acl"
#define kTypeKey @"_type"

@implementation KCSKinveyRef
- (id) initWithObj:(id<KCSPersistable>)obj andCollection:(NSString*)collection
{
    self = [super init];
    if (self) {
        obj = [obj isEqual:[NSNull null]] ? nil : obj;
        self.object = obj;
        self.collectionName = collection;
    }
    return self;
}

- (id)proxyForJson
{
    NSString* objId = [(id)self.object kinveyObjectId];
    return objId ? @{kTypeKey : @"KinveyRef", @"_collection" : self.collectionName, @"_id" : objId } : [NSNull null];
}

- (BOOL)isEqualDict:(NSDictionary*)dict
{
    return [[dict objectForKey:kTypeKey] isEqualToString:@"KinveyRef"] && [[dict objectForKey:@"_collection"] isEqualToString:self.collectionName] && [[dict objectForKey:@"_id"] isEqualToString:[(id)self.object kinveyObjectId]];
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[KCSKinveyRef class]]) {
        return [self isEqualDict:[obj proxyForJson]];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self isEqualDict:obj];
    } else {
        return NO;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<KCSKinveyRef: { objId : '%@', _collection : '%@'}>", [(id)self.object kinveyObjectId], self.collectionName];
}

- (BOOL) unableToSaveReference:(BOOL)savingReferences
{
    NSString* objId = [(id)self.object kinveyObjectId];
    return savingReferences == NO && objId == nil;
}

@end

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

- (id)initWithObject:(id<KCSPersistable>)object ofId:(NSString *)objectId dataToSerialize:(NSDictionary *)dataToSerialize resources:(NSArray*)resources references:(NSArray *)references
{
    self = [super init];
    if (self){
        _dataToSerialize = dataToSerialize;
        _objectId = [objectId copy];
        _isPostRequest = _objectId.length == 0;
        _resourcesToSave = resources;
        _referencesToSave = references;
        _handleToOriginalObject = object;
    }
    return self;
}


- (NSString *)debugDescription
{
    return [self.dataToSerialize description];
}

- (void) restoreReferences:(KCSSerializedObject*)previousObject
{
    //should be okay to overwrite except for id
    //this will put the object in an state not good execept for saving
    //anything that was updated in between will be refreshed by the subsequent save
    NSDictionary* old = previousObject.dataToSerialize;
    NSDictionary* new = [NSMutableDictionary dictionaryWithDictionary:self.dataToSerialize];
    for (NSString* key in [old allKeys]) {
        [new setValue:[old valueForKey:key] forKey:key];
    }
    _dataToSerialize = new;
    _referencesToSave = previousObject.referencesToSave;
}

@end

@implementation KCSObjectMapper
+ (id)populateObject:(id)object withData: (NSDictionary *)data {
    return [self populateObjectWithLinkedResources:object withData:data resourceDictionary:nil];
}

NSString* specialTypeOfValue(id value)
{
    NSString* type = nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        type = [value objectForKey:kTypeKey];
    } else if ([value isKindOfClass:[NSArray class]] && [value count] > 0) {
        type = specialTypeOfValue(value[0]);
    }
    return type;
}

+ (id)populateExistingObject:(KCSSerializedObject*)serializedObject withNewData:(NSDictionary*)data
{
    id object = serializedObject.handleToOriginalObject;
    
    BOOL hasFlatMap = NO;
    NSString *dictName = nil;
    
    NSDictionary *hostToJsonMap = [object hostToKinveyPropertyMapping];
    NSDictionary* properties = [KCSPropertyUtil classPropsFor:[object class]];
    
    NSDictionary *specialOptions = builderOptions(object);
    
    if (specialOptions != nil){
        dictName = [specialOptions objectForKey:KCS_DICTIONARY_NAME_KEY];
        if ([specialOptions objectForKey:KCS_USE_DICTIONARY_KEY]){
            hasFlatMap = YES;
        }
        
        if ([specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] != nil && [[specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] boolValue] == YES) {
            NSMutableDictionary* d  = [NSMutableDictionary dictionaryWithDictionary:hostToJsonMap];
            [d setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjects:[data allKeys] forKeys:[data allKeys]]];
            
            if ([d objectForKey:kKMDKey] || [d objectForKey:kACLKey]) {
                [d removeObjectForKey:kKMDKey];
                [d removeObjectForKey:kACLKey];
                [d setObject:KCSEntityKeyMetadata forKey:KCSEntityKeyMetadata];
            }
            hostToJsonMap = d;
        }

    }
    
    
    
    for (NSString *hostKey in hostToJsonMap) {
        NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];
        id value = nil;
        
        if ([jsonKey isEqualToString:KCSEntityKeyMetadata]) {
            NSDictionary* kmd = [data objectForKey:kKMDKey];
            NSDictionary* acl = [data objectForKey:kACLKey];
            KCSMetadata* metadata = [[KCSMetadata alloc] initWithKMD:kmd acl:acl];
            value = metadata;
        } else {
            value = [data valueForKey:jsonKey];
        }
        
        if (value == nil){
            KCSLogWarning(@"Data Mismatch, unable to find value for JSON Key: '%@' (Host Key: '%@').  Object not 100%% valid.", jsonKey, hostKey);
            continue;
        } else {
            NSString* maybeType = specialTypeOfValue(value);
            if (maybeType && [maybeType isEqualToString:@"resource"]) {
                //this is a linked resource; TODO: should support array?
                NSArray* resources = serializedObject.resourcesToSave;
                NSUInteger resIdx = [resources indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [obj isEqual:value];
                }];
                if (resIdx != NSNotFound) {
                    [object setValue:[resources[resIdx] resource] forKey:hostKey];
                } else {
                    [object setValue:value forKey:hostKey];
                }
            } else if (maybeType && [maybeType isEqualToString:@"KinveyRef"]) {
                //this is a reference
                NSArray* references = serializedObject.referencesToSave;
                if ([value isKindOfClass:[NSArray class]]) {
                    NSString* valueType = [properties valueForKey:hostKey];
                    Class valClass = objc_getClass([valueType UTF8String]);
                    id objVals = [NSMutableArray arrayWithCapacity:[value count]];
                    if (valClass != nil) {
                        objVals = [[[valClass alloc] init] mutableCopy];
                    }
                    
                   
                    for (id arVal in value) {
                        NSUInteger refIdx = [references indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                            return [obj isEqual:arVal];
                        }];
                        if (refIdx == NSNotFound) {
                            [objVals addObject:arVal];
                        } else {
                            [objVals addObject:[references[refIdx] object]];
                        }
                    }
                    [object setValue:objVals forKey:hostKey];
                } else {
                    NSUInteger refIdx = [references indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return [obj isEqual:value];
                    }];
                    if (refIdx != NSNotFound) {
                        [object setValue:[references[refIdx] object] forKey:hostKey];
                    } else {
                        id oldVal = [object valueForKey:hostKey];
                        NSString* refId = [value objectForKey:@"_id"];
                        BOOL hasAnObjectAlreadyAssigned = oldVal != nil && refId != nil && [refId isEqualToString:[oldVal kinveyObjectId]];
                        if (hasAnObjectAlreadyAssigned == NO) {
                            [object setValue:value forKey:hostKey];
                        }
                    }
                }
            } else {
                NSString* valueType = [properties valueForKey:hostKey];
                Class valClass = objc_getClass([valueType UTF8String]);
                Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
                if (builder != nil) {
                    id builtValue = [builder objectForJSONObject:value];
                    [object setValue:builtValue forKey:hostKey];
                } else {
                    if ([jsonKey isEqualToString:KCSEntityKeyId] && [object kinveyObjectId] != nil && [[object kinveyObjectId] isEqualToString:value] == NO) {
                        KCSLogWarning(@"%@ is having it's id overwritten.", object);
                    }
                    if ([object respondsToSelector:@selector(setValue:forKey:)]) {
                        [object setValue:value forKey:hostKey];
                    } else {
                        KCSLogWarning(@"%@ cannot setValue for %@", hostKey);
                    }
                }
            }
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
    
    return object;
}

+ (id) makeObjectFromKinveyRef:(id)refDict forClass:(Class) valClass
{
    if ([refDict isEqual:[NSNull null]]) {
        return [NSNull null];
    }
    id referencedObj = [refDict objectForKey:@"_obj"];
    
    //TODO: how to handle resources!
    id newObj = refDict;
    if (referencedObj != nil) {
        BOOL isAKCSPersistable = [valClass conformsToProtocol:@protocol(KCSPersistable)];
        if (isAKCSPersistable == YES) {
            newObj = [self makeObjectWithResourcesOfType:valClass withData:referencedObj withResourceDictionary:nil];
        } else {
            newObj = referencedObj;
        }
    }
    return newObj;
    
}

//TODO: figure out how to combine with above
+ (id)populateObjectWithLinkedResources:(id)object withData: (NSDictionary *)data resourceDictionary:(NSMutableDictionary*)resourcesToLoad
{
    BOOL hasFlatMap = NO;
    NSString *dictName = nil;
    NSDictionary* referencesClasses = @{};
    
    NSDictionary *hostToJsonMap = [object hostToKinveyPropertyMapping];
    NSDictionary* properties = [KCSPropertyUtil classPropsFor:[object class]];
    
    NSDictionary *specialOptions = builderOptions(object);
    
    if (specialOptions != nil){
        dictName = [specialOptions objectForKey:KCS_DICTIONARY_NAME_KEY];
        if ([specialOptions objectForKey:KCS_USE_DICTIONARY_KEY]){
            hasFlatMap = YES;
        }
        if ([specialOptions objectForKey:KCS_REFERENCE_MAP_KEY] != nil) {
            referencesClasses = [specialOptions objectForKey:KCS_REFERENCE_MAP_KEY];
        }
        if ([specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] != nil && [[specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] boolValue] == YES) {
            NSMutableDictionary* d  = [NSMutableDictionary dictionaryWithDictionary:hostToJsonMap];
            [d setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjects:[data allKeys] forKeys:[data allKeys]]];
            
            if ([d objectForKey:kKMDKey] || [d objectForKey:kACLKey]) {
                [d removeObjectForKey:kKMDKey];
                [d removeObjectForKey:kACLKey];
                [d setObject:KCSEntityKeyMetadata forKey:KCSEntityKeyMetadata];
            }
            hostToJsonMap = d;
        }
    }
    
    for (NSString *hostKey in hostToJsonMap) {
        NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];
        id value = nil;
        
        if ([jsonKey isEqualToString:KCSEntityKeyMetadata]) {
            NSDictionary* kmd = [data objectForKey:kKMDKey];
            NSDictionary* acl = [data objectForKey:kACLKey];
            KCSMetadata* metadata = [[KCSMetadata alloc] initWithKMD:kmd acl:acl];
            value = metadata;
        } else {
            value = [data valueForKey:jsonKey];
        }
        
        if (value == nil){
            KCSLogWarning(@"Data Mismatch, unable to find value for JSON Key: '%@' (Host Key: '%@').  Object not 100%% valid.", jsonKey, hostKey);
            continue;
        } else {
            NSString* maybeType = specialTypeOfValue(value);
            if (maybeType && [maybeType isEqualToString:@"resource"]) {
                //this is a linked resource; TODO: should support array?
                //TODO: DIFF-----
                [resourcesToLoad setObject:value forKey:hostKey];
            } else if (maybeType && [maybeType isEqualToString:@"KinveyRef"]) {
                //this is a reference
                //TODO: DIFF-----
                //TODO: update sig
                
                Class valClass = [referencesClasses objectForKey:hostKey];
                if (!valClass) {
                    NSString* valueType = [properties valueForKey:hostKey];
                    valClass = objc_getClass([valueType UTF8String]);
                }
                
                if ([value isKindOfClass:[NSArray class]]) {
                    NSString* valueType = [properties valueForKey:hostKey];
                    Class collectionClass = objc_getClass([valueType UTF8String]);
                    id objVals = [NSMutableArray arrayWithCapacity:[value count]];
                    if (collectionClass != nil) {
                        objVals = [[[collectionClass alloc] init] mutableCopy];
                    }
                    for (id arVal in value) {
                        [objVals addObject:[self makeObjectFromKinveyRef:arVal forClass:valClass]];
                    }
                    [object setValue:objVals forKey:hostKey];
                } else {
                    [object setValue:[self makeObjectFromKinveyRef:value forClass:valClass] forKey:hostKey];
                }
                
            } else {
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
    
    return object;
}

+ (id)makeObjectWithResourcesOfType:(Class)objectClass withData:(NSDictionary *)data withResourceDictionary:(NSMutableDictionary*)resources;
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
        copiedObject = [[objectClass alloc] init];
    }
    
    return [KCSObjectMapper populateObjectWithLinkedResources:copiedObject withData:data resourceDictionary:resources];
}

+ (id)makeObjectOfType:(Class)objectClass withData:(NSDictionary *)data
{
    return [self makeObjectWithResourcesOfType:objectClass withData:data withResourceDictionary:nil];
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultBuilders = @{(id)[NSDate class] : [KCSDateBuilder class],
        (id)[NSSet class] : [KCSSetBuilder class],
        (id)[NSMutableSet class] : [KCSMSetBuilder class],
        (id)[NSOrderedSet class] : [KCSOrderedSetBuilder class],
        (id)[NSMutableOrderedSet class] : [KCSMOrderedSetBuilder class],
        (id)[NSMutableAttributedString class] : [KCSMAttributedStringBuilder class],
        (id)[NSAttributedString class] : [KCSAttributedStringBuilder class],
        (id)[CLLocation class] : [KCSCLLocationBuilder class]};
    });

    return _defaultBuilders;
}

Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass);
Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass)
{
    NSDictionary* options = builderOptions(object);
    NSDictionary* builders = [options objectForKey:KCS_DICTIONARY_DATATYPE_BUILDER];
    Class<KCSDataTypeBuilder> builderClass = ifNotNil(builders, [builders objectForKey:valClass]);
    if (builderClass == nil) {
        NSDictionary* d = defaultBuilders();
        builderClass = [d objectForKey:valClass];
    }
    return ifNotNil(builderClass, builderClass);
}

BOOL isCollection(id obj)
{
    return [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]] || [obj isKindOfClass:[NSOrderedSet class]];
}

void setError(NSError** error, NSString* objectId, NSString* jsonName)
{
    if (error != NULL) {
        NSDictionary* info = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Reference object does not have ID set."],
        NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Object (id=%@) is trying to create a reference in field '%@', but that object does not yet have an assigned id. Save this object to its collection first", objectId, jsonName], NSLocalizedRecoverySuggestionErrorKey : @"Save reference object first or pre-assign it an id."};
        *error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSReferenceNoIdSetError userInfo:info];
    }
}

+ (KCSSerializedObject*) makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName withProps:(BOOL)withProps error:(NSError**)error
{
    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [object hostToKinveyPropertyMapping];
    NSString *objectId = @"";
    
    NSMutableArray* resourcesToSave = nil;
    NSMutableArray* referencesToSave = nil;
    NSDictionary* kinveyRefMapping = nil;
    
    if (withProps == YES) {
        resourcesToSave = [NSMutableArray array];
        if ([[object class] respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
            referencesToSave = [NSMutableArray array];
            kinveyRefMapping = [[object class] kinveyPropertyToCollectionMapping];
        }
    }
    
    for (NSString* key in kinveyMapping) {
        NSString *jsonName = [kinveyMapping valueForKey:key];
        id value = [object valueForKey:key];
        
        //get the id
        if ([jsonName isEqualToString:KCSEntityKeyId] && value != nil){
            objectId = value;
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
                NSString* objname = [object kinveyObjectId];
                if (objname == nil) {
                    CFUUIDRef uuid = CFUUIDCreate(NULL);
                    
                    if (uuid){
                        objname = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
                        CFRelease(uuid);
                    }
                }
                NSString* filename = [NSString stringWithFormat:@"%@-%@-%@%@", collectionName, objname, key, extensionForResource(value)];
                KCSResource* resourceWrapper = [[KCSResource alloc] initWithResource:value name:filename];
                [resourcesToSave addObject:resourceWrapper];
                [dictionaryToMap setValue:resourceWrapper forKey:jsonName];
            } else if (withProps == YES && [kinveyRefMapping objectForKey:jsonName] != nil) {
                // have a kinvey ref
                BOOL shouldSaveRef = [object respondsToSelector:@selector(referenceKinveyPropertiesOfObjectsToSave)] && [[object referenceKinveyPropertiesOfObjectsToSave] containsObject:jsonName] == YES;
                if (isCollection(value)) {
                    NSArray* arrayValue = value;
                    Class<KCSDataTypeBuilder> builder = builderForComplexType(object, [value classForCoder]);
                    if (builder != nil) {
                        arrayValue = [builder JSONCompatabileValueForObject:value];
                    }
                    NSMutableArray* refArray = [NSMutableArray arrayWithCapacity:[arrayValue count]];
                    for (id arrayVal in arrayValue) {
                        KCSKinveyRef* ref = [[KCSKinveyRef alloc] initWithObj:arrayVal andCollection:[kinveyRefMapping objectForKey:jsonName]];
                        if ([ref unableToSaveReference:shouldSaveRef]) {
                            setError(error, objectId, jsonName);
                            return nil;
                        }
                        [refArray addObject:ref];
                    }
                    if (shouldSaveRef) {
                        [referencesToSave addObjectsFromArray:refArray];
                    }
                    [dictionaryToMap setValue:refArray forKey:jsonName];
                } else {
                    KCSKinveyRef* ref = [[KCSKinveyRef alloc] initWithObj:value andCollection:[kinveyRefMapping objectForKey:jsonName]];
                    if ([ref unableToSaveReference:shouldSaveRef]) {
                        setError(error, objectId, jsonName);
                        return nil;
                    }
                    [dictionaryToMap setValue:ref forKey:jsonName];
                    if (shouldSaveRef) {
                        [referencesToSave addObject:ref];
                    }
                }
            } else {
                Class valClass = [value classForCoder];
                Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
                if (builder != nil) {
                    id jsonType = [builder JSONCompatabileValueForObject:value];
                    [dictionaryToMap setValue:jsonType forKey:jsonName];
                } else {
                    //TODO: handle complex types
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
    
    return [[KCSSerializedObject alloc] initWithObject:object ofId:objectId dataToSerialize:dictionaryToMap resources:resourcesToSave references:referencesToSave];
}

+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName error:(NSError**)error
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:collectionName withProps:YES error:error];
}

+ (KCSSerializedObject *)makeKinveyDictionaryFromObject: (id)object error:(NSError**)error
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:nil withProps:NO error:error];
}

@end
