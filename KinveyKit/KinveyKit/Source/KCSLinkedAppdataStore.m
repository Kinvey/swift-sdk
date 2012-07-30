//
//  KCSLinkedAppdataStore.m
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey, Inc. All rights reserved.
//

#import "KCSLinkedAppdataStore.h"

#import "KCSRESTRequest.h"
#import "KCSObjectMapper.h"
#import "KinveyCollection.h"
#import "KCS_SBJsonWriter.h"
#import "KCS_SBJsonParser.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "KCSLogManager.h"
#import "KCSConnectionProgress.h"

#import "NSArray+KinveyAdditions.h"

#import "KCSResourceStore.h"
#import "KCSResource.h"


@interface DoubleHolder : NSObject 
@property (nonatomic) double doubleVal;
@end
@implementation DoubleHolder
@synthesize doubleVal;
@end

@interface EntityQueue : NSObject {
    NSMutableArray* _array;
    KCSSerializedObject* _entity;
}
+ (EntityQueue*) enqueue:(id)object;
@property (nonatomic, retain) KCSSerializedObject* entity;
@end
@implementation EntityQueue
@synthesize entity = _entity;
+ (EntityQueue*) enqueue:(id)object
{
    if ([object isKindOfClass:[NSArray class]]) {
        return [[[EntityQueue alloc] initWithArray:object] autorelease];
    } else {
        return [[[EntityQueue alloc] initWithObject:object] autorelease];
    }
}

+ (EntityQueue*) enqueueEntity:(KCSSerializedObject*)object
{
    return [[[EntityQueue alloc] initWithSerializedObject:object] autorelease];
}

- (id) initWithSerializedObject:(KCSSerializedObject*)object
{
    self = [self initWithArray:object.resourcesToSave];
    if (self) {
        _entity = [object retain];
    }
    return self;
}

- (id) initWithArray:(NSArray*) array
{
    self = [super init];
    if (self) {
        _array = [[NSMutableArray arrayWithArray:array] retain];
    }
    return self;
}

- (id) initWithObject:(id)object
{
    self = [super init];
    if (self) {
        _array = [NSMutableArray arrayWithObject:object];
    }
    return self;
}

- (void) dealloc
{
    [_entity release];
    [_array release];
    [super dealloc];
}

- (id) popResource
{
    id item = nil;
    @synchronized(self) {
        if (_array.count > 0) {
            item = [_array objectAtIndex:0];
            [_array removeObject:item];
        }
    }
    return item;
}

- (NSUInteger) count
{
    return [_array count];
}

@end

@interface KCSAppdataStore ()
- (id)initWithAuth: (KCSAuthHandler *)auth;
- (BOOL) validatePreconditionsAndSendErrorTo:(void(^)(id objs, NSError* error))completionBlock;
typedef KCSRESTRequest* (^RestRequestForObjBlock_t)(id obj);
typedef NSArray* (^ProcessDataBlock_t)(KCSConnectionResponse* response, NSError** error);
- (void) operation:(id)object RESTRequest:(RestRequestForObjBlock_t)requestBlock dataHandler:(ProcessDataBlock_t)processBlock completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;
- (void) saveEntity:(KCSSerializedObject*)serializedObj withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock;
@property (nonatomic, retain) KCSCollection *backingCollection;
@property (nonatomic) BOOL treatSingleFailureAsGroupFailure;
@end

@implementation KCSLinkedAppdataStore

#pragma mark - Saving
- (void) buildObjectFromJSON:(NSDictionary*)dictValue withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    id obj = [KCSObjectMapper makeObjectWithResorucesOfType:self.backingCollection.objectTemplate withData:dictValue withDictionary:resources];
    __block NSUInteger resourceCount = resources.count;
    if (resourceCount > 0) {
        KCSResourceStore* resourceStore = [KCSResourceStore store];
        for (NSString* key in [resources allKeys]) {
                NSDictionary* resource = [resources valueForKey:key];
                [resourceStore loadObjectWithID:[resource valueForKey:kKCSResourceLocationKey] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if (errorOrNil == nil && objectsOrNil != nil) {
                        NSData* response = [objectsOrNil objectAtIndex:0];
                        id realResource = [KCSResource resourceObjectFromData:response type:[resource valueForKey:kKCSResourceMimeTypeKey]];                         [obj setValue:realResource forKey:key];
                        if (--resourceCount == 0) {
                            completionBlock([NSArray arrayWithObject:obj], nil);
                        }
                    } else {
                        completionBlock([NSArray arrayWithObject:obj], errorOrNil);
                    }
                } withProgressBlock:nil]; //TODO: handle progress
        }
    } else {
        completionBlock([NSArray arrayWithObject:obj], nil);
    }
}

- (void) saveEntityResource:(EntityQueue*)resourceQueue totalbytes:(unsigned long int)bytecount cumulativeProgress:(DoubleHolder*)progress withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    KCSResource* aResource = [resourceQueue popResource];
    if (aResource != nil) {
        NSData* aData = [aResource data];
        double thispercent = [aData length] / (long double) bytecount;
        
        KCSResourceStore* resourceStore = [KCSResourceStore store];
        [resourceStore saveData:aData toFile:[aResource blobName] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            //TODO: what do with return object?
            
            if (errorOrNil != nil) {
                completionBlock(nil, errorOrNil);
            } else {
                [self saveEntityResource:resourceQueue totalbytes:bytecount cumulativeProgress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
            }
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            //TODO: deal with return objects
            double current = progress.doubleVal + percentComplete * thispercent;
            if (progressBlock != nil) {
                progressBlock(objects, current);
            }
            progress.doubleVal = current;
        }];
    } else {
        //save entity
        KCSSerializedObject* entity = resourceQueue.entity;
        [self saveEntity:entity withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            completionBlock(objectsOrNil, errorOrNil);
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
            NSData* data = [writer dataWithObject:entity.dataToSerialize];
            double thisperecent = [data length] / (long double) bytecount;
            double current = progress.doubleVal + percentComplete * thisperecent;
            if (progressBlock != nil) {
                progressBlock(objects, current);
            }
            progress.doubleVal = current;
        }];
    }
}

unsigned long int countBytes(NSArray* objectsToSave);
unsigned long int countBytes(NSArray* objectsToSave)
{
    unsigned long int bytecount = 0;
    
    for (id <KCSPersistable> singleEntity in objectsToSave) {
        KCSSerializedObject* serializedObj = [KCSObjectMapper makeResourceEntityDictionaryFromObject:singleEntity forCollection:@""];
        NSDictionary *dictionaryToMap = [serializedObj.dataToSerialize retain];
        KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
        NSData* data = [writer dataWithObject:dictionaryToMap];
        [dictionaryToMap release];
        bytecount += [data length];
        
        
        NSArray* resources = [serializedObj resourcesToSave];
        
        for (KCSResource* resource in resources) {
            data = [resource data];
            bytecount += [data length];
            
        }
    }
    return bytecount;
}

- (void) saveObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    NSArray* objectsToSave = [NSArray wrapIfNotArray:object];
    int totalItemCount = [objectsToSave count];
    unsigned long int bytecount = progressBlock == nil ? LONG_MAX : countBytes(objectsToSave); //don't go through the work to count the bytes if no progress block
    
    __block int completedItemCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalItemCount];
    
    DoubleHolder* progress = [[[DoubleHolder alloc] init] autorelease];
    progress.doubleVal = 0.;
    
    __block NSError* topError = nil;
    __block BOOL done = NO;
    for (id <KCSPersistable> singleEntity in objectsToSave) {
        KCSSerializedObject* serializedObj = [KCSObjectMapper makeResourceEntityDictionaryFromObject:singleEntity forCollection:self.backingCollection.collectionName];
        EntityQueue* resourceQueue = [EntityQueue enqueueEntity:serializedObj]; 

        [self saveEntityResource:resourceQueue totalbytes:bytecount cumulativeProgress:progress withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (done) {
                //don't do the completion blocks for all the objects if its previously finished
                return;
            }
            if (errorOrNil != nil) {
                topError = errorOrNil;
            }
            if (objectsOrNil != nil) {
                [completedObjects addObjectsFromArray:objectsOrNil];
            }
            completedItemCount++;
            BOOL shouldStop = errorOrNil != nil && self.treatSingleFailureAsGroupFailure;
            if (completedItemCount == totalItemCount || shouldStop) {
                done = YES;
                completionBlock(completedObjects, topError);
            }
        } withProgressBlock:progressBlock];
    }    
 }

@end
