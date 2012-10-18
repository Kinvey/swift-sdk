//
//  KCSLinkedAppdataStore.m
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey, Inc. All rights reserved.
//

#import "KCSLinkedAppdataStore.h"

#import "KCSObjectMapper.h"
#import "KinveyCollection.h"
#import "NSArray+KinveyAdditions.h"
#import "KCSResourceStore.h"
#import "KCSResource.h"
#import "KCSBlobService.h"
#import "KCSSaveGraph.h"
#import "KCSHiddenMethods.h"

@interface KCSAppdataStore ()
@property (nonatomic, retain) KCSCollection *backingCollection;
- (void) saveMainEntity:(KCSSerializedObject*)serializedObj progress:(KCSSaveGraph*)progress withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock;
@end

@implementation KCSLinkedAppdataStore

#pragma mark - Saving
- (void) saveEntityWithReferences:(KCSSerializedObject*)so progress:(KCSSaveGraph*)progress withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    //Step 2: Save References
    NSArray* references = so.referencesToSave;
    int totalReferences = references.count;
    
    if (totalReferences == 0) {
        //no references, go on to saving object
        [self saveMainEntity:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } else {
        __block NSError* referenceError = nil;
        __block int completedCount = 0;
        
        for (KCSKinveyRef* reference in references) {
            id objKey = [progress addReference:reference.object entity:[so.userInfo objectForKey:@"entityProgress"]];
            if ([objKey isKindOfClass:[NSNumber class]] == NO) {
                KCSLinkedAppdataStore* appdataStore = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:reference.collectionName ofClass:[reference.object class]] options: @{KCSStoreKeyOngoingProgress : progress, KCSStoreKeyTitle : [NSString stringWithFormat:@"sub-save for: %@",reference.object]}];
                [appdataStore saveObject:reference.object withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if (errorOrNil != nil) {
                        completionBlock(nil, errorOrNil);
                    } else {
                        //Step 2a: replace id in reference - done when object is returned from saving
                        //Step 2b: replace field with kinveyref -> done in step 0 (serialize obj)
                        
                        if (errorOrNil && !referenceError) {
                            referenceError = errorOrNil;
                        }
                        completedCount++;
                        if (completedCount == totalReferences) {
                            //DONE
                            if (referenceError) {
                                completionBlock(nil, referenceError);
                            } else {
                                [self saveMainEntity:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
                            }
                        }
                        
                    }
                } withProgressBlock:^(NSArray *objects, double percentComplete) {
                    //TODO: what to do with objects
                    [objKey setPc:percentComplete];
                    if (progressBlock != nil) {
                        progressBlock(objects, progress.percentDone);
                    }
                }];
            } else {
                bool needToWait = [objKey boolValue];
                if (needToWait == YES) {
                    [progress tell:reference.object toWaitForResave:so.handleToOriginalObject];
                }
                //already sent object to be saved
                completedCount++;
                if (completedCount == totalReferences) {
                    //DONE
                    if (referenceError) {
                        completionBlock(nil, referenceError);
                    } else {
                        [self saveMainEntity:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
                    }
                }
            }
        }
    }
}

//override KCSAppdatastore
- (void) saveEntityWithResources:(KCSSerializedObject*)so progress:(KCSSaveGraph*)progress withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    //Step 1: Save Resources
    NSArray* resources = so.resourcesToSave;
    int totalResources = resources.count;
    
    if (totalResources == 0) {
        //no resources, go on to saving references
        [self saveEntityWithReferences:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } else {
        __block NSError* resourceError = nil;
        __block int completedCount = 0;
        
        for (KCSResource* resource in resources) {
            NSData* aData = [resource data];
            //TODO: check
            id objKey = [progress addResource:resource entity:[so.userInfo objectForKey:@"entityProgress"]];
            
            KCSResourceStore* resourceStore = [KCSResourceStore store];
            [resourceStore saveData:aData toFile:[resource blobName] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (errorOrNil && !resourceError) {
                    resourceError = errorOrNil;
                }
                if (objectsOrNil != nil && objectsOrNil.count > 0) {
                    //TODO: what do with return object?
                    //KCSResourceResponse* r = [objectsOrNil objectAtIndex:0];
                }
                completedCount++;
                if (completedCount == totalResources) {
                    //DONE
                    if (resourceError) {
                        completionBlock(nil, resourceError);
                    } else {
                        [self saveEntityWithReferences:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
                    }
                }
            } withProgressBlock:^(NSArray *objects, double percentComplete) {
                //TODO: what to do with objects
                [objKey setPc:percentComplete];
                if (progressBlock != nil) {
                    progressBlock(objects, progress.percentDone);
                }
            }];
            
        }
    }
}

- (KCSSerializedObject*) makeSO:(id<KCSPersistable>)object error:(NSError**)error
{
    return [KCSObjectMapper makeResourceEntityDictionaryFromObject:object forCollection:self.backingCollection.collectionName error:error];
}

#pragma mark - Querying/Fetching
//override KCSAppdatastore
- (id) manufactureNewObject:(NSDictionary*)jsonDict resourcesOrNil:(NSMutableDictionary*)resources
{
    return [KCSObjectMapper makeObjectWithResourcesOfType:self.backingCollection.objectTemplate withData:jsonDict withResourceDictionary:resources];
}

//TODO:group resolves?

- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy
{
    
    
    if ([self.backingCollection.objectTemplate respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        NSDictionary* hostResolves = [self.backingCollection.objectTemplate kinveyPropertyToCollectionMapping];
        NSArray* resolvesArray = [hostResolves allKeys];
        [query setReferenceFieldsToResolve:resolvesArray];
    }
    [super queryWithQuery:query withCompletionBlock:completionBlock withProgressBlock:progressBlock cachePolicy:cachePolicy];
}

//override KCSAppdatastore
- (NSString*) modifyLoadQuery:(NSString*)query ids:(NSArray*)array
{
    if ([self.backingCollection.objectTemplate respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        NSDictionary* hostResolves = [self.backingCollection.objectTemplate kinveyPropertyToCollectionMapping];
        NSArray* resolvesArray = [hostResolves allKeys];
        NSString* resolveType = (array.count == 1) ? @"?resolve=" : @"&resolve=";
        query = [query stringByAppendingString:[resolveType stringByAppendingString:[resolvesArray join:@","]]];
    }
    return query;
}
@end
