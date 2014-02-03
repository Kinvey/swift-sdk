//
//  KCSPersistableDescription.m
//  KinveyKit
//
//  Copyright (c) 2014 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

#import "KCSPersistableDescription.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

@interface KCSReferenceDescription ()
//@property (nonatomic, copy) NSString* sourceEntity;
@property (nonatomic, copy) NSString* classname; //TODO: needed?
@property (nonatomic) BOOL isContainer;
@end

@implementation KCSReferenceDescription


- (id<KCSPersistable2>) destinationObjFromObj:(NSObject<KCSPersistable2>*)sourceObj
{
    return [sourceObj valueForKeyPath:self.sourceProperty];
}

@end


@interface KCSPersistableDescription ()
@property (nonatomic, copy) NSString* collection;
@property (nonatomic, retain) NSDictionary* fieldToPropertyMapping;
@property (nonatomic, retain) NSDictionary* propertyToFieldMapping;
- (NSString*) objectIdFromObject:(id<KCSPersistable2>)obj;
@end

@implementation KCSPersistableDescription

BOOL kcsIsContainerClass(Class aClass)
{
    return [aClass isSubclassOfClass:[NSArray class]] || [aClass isSubclassOfClass:[NSDictionary class]] || [aClass isSubclassOfClass:[NSSet class]] || [aClass isSubclassOfClass:[NSOrderedSet class]];
    // || [aClass isKindOfClass:[NSMutableArray class]] || [aClass isKindOfClass:[NSMutableDictionary class]] || [aClass isKindOfClass:[NSMutableSet class]] || [aClass isKindOfClass:[NSMutableOrderedSet class]];
}

- (NSArray*) discoverReferences:(id<KCSPersistable>)object
{
    NSArray* refs = nil;
    if (object) {
        Class objClass = [object class];
        if ([objClass respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
            NSDictionary* mapping = [[object class] kinveyPropertyToCollectionMapping];
            NSMutableArray* mRefs = [NSMutableArray arrayWithCapacity:mapping.count];
            
            NSDictionary* classProps = [KCSPropertyUtil classPropsFor:objClass];
            
            [mapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                KCSReferenceDescription* rd = [[KCSReferenceDescription alloc] init];
                rd.sourceField = key;
                rd.destinationCollection = obj;
                
                NSUInteger dotLocation = [(NSString*)key rangeOfString:@"."].location;
                NSString* refField = dotLocation == NSNotFound ? key : [key substringToIndex:dotLocation];
                NSString* sourceProp = self.fieldToPropertyMapping[refField];
                NSAssert(sourceProp, @"No property mapping for field '%@'", key);
                rd.sourceProperty = sourceProp;
                
                rd.classname = classProps[rd.sourceProperty];
                rd.isContainer = kcsIsContainerClass(NSClassFromString(rd.classname));
                [mRefs addObject:rd];
            }];
            refs = mRefs;
        }
    }
    return refs;
}

- (instancetype) initWithKinveyKit1Object:(id<KCSPersistable>)object collection:(NSString*)collection
{
    self = [super init];
    if (self) {
        //WARNING: ordering matters, below! Each property builds on the previous
        _collection = collection;
        _propertyToFieldMapping = [[object hostToKinveyPropertyMapping] copy];
        _fieldToPropertyMapping = [_propertyToFieldMapping invert];
        _references = [self discoverReferences:object];
    }
    return self;
}

#pragma mark - Object Helpers

- (NSString *)objectIdFromObject:(id<KCSPersistable2>)obj
{
    return [obj valueForKey:self.fieldToPropertyMapping[KCSEntityKeyId]];
}

#pragma mark - Graph Helpers
- (void) addRefsFromContainer:(id)objContainer desc:(KCSReferenceDescription*)rDesc graph:(NSMutableDictionary*)graph
{
    NSMutableSet* thisSet = graph[rDesc.destinationCollection];
    
    NSString* entityPath = rDesc.sourceField;
    
    NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"."].location;
    if (dotLocation != NSNotFound) {
        NSString* keyPath = [entityPath substringFromIndex:dotLocation+1];
        objContainer = [objContainer valueForKeyPath:keyPath];
    }

    
    if ([objContainer isKindOfClass:[NSArray class]]) {
//        NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"." options:NSBackwardsSearch].location;
//        BOOL hasKeyPath = dotLocation != NSNotFound;
//        NSString* keyPath = hasKeyPath ? [entityPath substringFromIndex:dotLocation+1] : entityPath;
//
//        if (hasKeyPath) {
//            [thisSet addObjectsFromArray:[objContainer valueForKeyPath:keyPath]];
//        } else {
            [thisSet addObjectsFromArray:objContainer];
//        }
    } else if ([objContainer isKindOfClass:[NSSet class]]) {
        [thisSet unionSet:objContainer];
    } else if ([objContainer isKindOfClass:[NSOrderedSet class]]) {
        [thisSet addObjectsFromArray:[objContainer array]];
    } else if ([objContainer isKindOfClass:[NSDictionary class]]) {
        //TODO? remove this?
        NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"."].location;
        NSString* keyPath = dotLocation == NSNotFound ? entityPath : [entityPath substringFromIndex:dotLocation+1];

        id obj = [objContainer valueForKeyPath:keyPath];
        if (obj) {
            if (kcsIsContainerClass([obj class])) {
                [self addRefsFromContainer:obj desc:rDesc graph:graph];
            } else {
                [thisSet addObject:obj];
            }
        }
    } else {
        if (objContainer) {
            [thisSet addObject:objContainer];
            //        DBAssert(NO, @"Container should be one the tested classes.");
        }
    }
}

//TODO: pull back refdescription as private class?
- (NSDictionary*) objectListFromObjects:(NSArray*)objects
{
    if (objects.count == 0) {
        return @{};
    }
    
    NSString* collection = self.collection;
    
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    d[collection] = [NSMutableSet setWithCapacity:objects.count];
    for (id<KCSPersistable2> obj in objects) {
        [d[collection] addObject:obj];
        NSArray* refs = self.references;
        for (KCSReferenceDescription* rdesc in refs) {
            id<KCSPersistable2> refObj = [rdesc destinationObjFromObj:obj];
            if (refObj) {
                if (!d[rdesc.destinationCollection]) {
                    d[rdesc.destinationCollection] = [NSMutableSet set];
                }
                if (rdesc.isContainer) {
                    [self addRefsFromContainer:refObj desc:rdesc graph:d];
                } else {
                    [d[rdesc.destinationCollection] addObject:refObj];
                }
            }
        }
    }
    return d;
}

@end
