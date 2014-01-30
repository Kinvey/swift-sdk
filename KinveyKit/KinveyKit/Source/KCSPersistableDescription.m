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
@property (nonatomic, retain) KCSPersistableDescription* sourceEntity;
@property (nonatomic, copy) NSString* classname; //TODO: needed?
@property (nonatomic) BOOL isContainer;
@end

@implementation KCSReferenceDescription


- (id<KCSPersistable2>) destinationObjFromObj:(id<KCSPersistable2>)sourceObj
{
    return [sourceObj valueForKey:self.sourceProperty];
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
    return [aClass isKindOfClass:[NSArray class]] || [aClass isKindOfClass:[NSDictionary class]] || [aClass isKindOfClass:[NSSet class]] || [aClass isKindOfClass:[NSOrderedSet class]];
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
                rd.sourceEntity = key;
                rd.destinationCollection = obj;
                rd.sourceProperty = self.fieldToPropertyMapping[key];
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
                    
                } else {
                    [d[rdesc.destinationCollection] addObject:refObj];
                    
                }
            }
        }
    }
    return d;
}

@end
