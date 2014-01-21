//
//  KCSLinkedAppdataStore.m
//  KinveyKit
//
//  Copyright (c) 2012-2014 Kinvey, Inc. All rights reserved.
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


#import "KCSLinkedAppdataStore.h"

#import "KCSObjectMapper.h"
#import "KinveyCollection.h"
#import "NSArray+KinveyAdditions.h"
#import "KCSFile.h"
#import "KCSFileStore.h"
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
    NSUInteger totalReferences = references.count;
    
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
    NSUInteger totalResources = resources.count;
    
    if (totalResources == 0) {
        //no resources, go on to saving references
        [self saveEntityWithReferences:so progress:progress withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } else {
        __block NSError* resourceError = nil;
        __block int completedCount = 0;
        
        for (KCSFile* resource in resources) {
            id objKey = [progress addResource:resource entity:[so.userInfo objectForKey:@"entityProgress"]];
            [KCSFileStore uploadKCSFile:resource options:nil completionBlock:^(KCSFile* uploadInfo, NSError *error) {
                if (error && !resourceError) {
                    resourceError = error;
                }
                if (uploadInfo != nil) {
                    //should update the reference from the server
                    [resource updateAfterUpload:uploadInfo];
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
            } progressBlock:^(NSArray *objects, double percentComplete) {
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

KK2(abstract out all of this)
- (NSString*) refStr
{
    NSString* refStr = nil;
    if ([self.backingCollection.objectTemplate respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        NSDictionary* hostResolves = [self.backingCollection.objectTemplate kinveyPropertyToCollectionMapping];
        NSArray* resolvesArray = [hostResolves allKeys];
        refStr = [@"?resolve=" stringByAppendingString:[resolvesArray join:@","]];
    }
    return refStr;
}


- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy
{
    if ([self.backingCollection.objectTemplate respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        NSDictionary* hostResolves = [self.backingCollection.objectTemplate kinveyPropertyToCollectionMapping];
        NSArray* resolvesArray = [hostResolves allKeys];
        [query setReferenceFieldsToResolve:resolvesArray];
    }
    [super queryWithQuery:query withCompletionBlock:completionBlock withProgressBlock:progressBlock cachePolicy:cachePolicy];
}

@end
