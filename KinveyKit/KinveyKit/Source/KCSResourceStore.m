//
//  KCSResourceStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/3/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSResourceStore.h"
#import "KCSBlobService.h"
#import "KCSBlockDefs.h"
#import "KCSResource.h"

#import "NSArray+KinveyAdditions.h"
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"

@interface KCSResourceStore ()

@end

@implementation KCSResourceStore

@synthesize authHandler = _authHandler;

#pragma mark -
#pragma mark Initialization

- (id)init
{
    return [self initWithAuth:nil];
}


- (id)initWithAuth: (KCSAuthHandler *)auth
{
    self = [super init];
    if (self) {
        _authHandler = [auth retain];
    }
    return self;
}

- (void) dealloc
{
    [_authHandler release];
    [super dealloc];
}

+ (id)store
{
    return [self storeWithAuthHandler:nil withOptions:nil];
}

+ (id)storeWithOptions: (NSDictionary *)options
{
    return [self storeWithAuthHandler:nil withOptions:options];
}

+ (id)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSResourceStore *store = [[[self alloc] initWithAuth:authHandler] autorelease];
    
    [store configureWithOptions:options];
    
    return store;
}


#pragma mark - Adding/Updating
- (void)saveObject: (id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];
    
    int totalObjects = objectsToProcess.count;
    if (totalObjects == 0) {
        completionBlock(nil, nil);
    }
    
    __block int completedCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalObjects];
    __block NSError* topError = nil;
    
    for (id entity in objectsToProcess) {
        if ([entity isKindOfClass:[KCSResource class]]) {
            [KCSResourceService saveData:[(KCSResource*)entity data] toResource:[(KCSResource*)entity blobName] completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (errorOrNil != nil) {
                    topError = errorOrNil;
                }
                if (objectsOrNil != nil) {
                    [completedObjects addObjectsFromArray:objectsOrNil];
                }
                completedCount++;
                if (completedCount == totalObjects) {
                    completionBlock(completedObjects, topError);
                }
            } progressBlock:^(NSArray *objects, double percentComplete) {
                if (progressBlock != nil) {
                    progressBlock(objects, completedCount / (double) totalObjects + percentComplete /(double) totalObjects);
                }
            }];
        } else if ([entity isKindOfClass:[NSURL class]]) {
            // This is where the work will be required...
            [KCSResourceService saveLocalResourceWithURL:entity completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (errorOrNil != nil) {
                    topError = errorOrNil;
                }
                if (objectsOrNil != nil) {
                    [completedObjects addObjectsFromArray:objectsOrNil];
                }
                completedCount++;
                if (completedCount == totalObjects) {
                    completionBlock(completedObjects, topError);
                }
            } progressBlock:^(NSArray *objects, double percentComplete) {
                if (progressBlock != nil) {
                    progressBlock(objects, completedCount / (double) totalObjects + percentComplete /(double) totalObjects);
                }
            }];
        } else {
            //not a NSURL (only accepted type in 1.4), generate error and continue
            completedCount++;
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Resource save was unsuccessful."
                                                                               withFailureReason:@"Object was not a NSURL-type"
                                                                          withRecoverySuggestion:@"saveObject: requires a NSURL to a local resource"
                                                                             withRecoveryOptions:nil];
            topError = [NSError errorWithDomain:KCSResourceErrorDomain
                                           code:KCSPrecondFailedError
                                       userInfo:userInfo];
            
            if (completedCount == totalObjects) {
                completionBlock(completedObjects, topError);
            }
        }
    }
    
}

- (void)saveData:(NSData*)data toFile:(NSString*)file withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [KCSResourceService saveData:data toResource:file completionBlock:completionBlock progressBlock:progressBlock];
}

#pragma mark -
#pragma mark Querying/Fetching
- (void)loadObjectWithID:(id)objectID withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [KCSResourceService downloadResource:objectID completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSMutableArray* newObjects = nil;
        if (objectsOrNil != nil && [objectsOrNil count] > 0) {
            newObjects = [NSMutableArray arrayWithCapacity:[objectsOrNil count]];
            for (KCSResourceResponse* response in objectsOrNil) {
                id responseObj = response.resource;
                [newObjects addObject:responseObj];
            }
        }
        completionBlock(newObjects, errorOrNil);
    } progressBlock:progressBlock];
}

- (void)queryWithQuery:(id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:query];
    int totalObjects = objectsToProcess.count;
    if (totalObjects == 0) {
        completionBlock(nil, nil);
    }
    
    __block int completedCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalObjects];
    __block NSError* topError = nil;
    
    for (id entity in objectsToProcess) {
        if ([entity isKindOfClass:[NSString class]]) {
            
            // This is where the work will be required...
            [KCSResourceService downloadResource:entity completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (errorOrNil != nil) {
                    topError = errorOrNil;
                }
                if (objectsOrNil != nil) {
                    [completedObjects addObjectsFromArray:objectsOrNil];
                }
                completedCount++;
                if (completedCount == totalObjects) {
                    completionBlock(completedObjects, topError);
                }
            } progressBlock:^(NSArray *objects, double percentComplete) {
                if (progressBlock != nil) {
                    progressBlock(objects, completedCount / (double) totalObjects + percentComplete /(double) totalObjects);
                }
            }];
        } else {
            //not a NSString (only accepted type in 1.4), generate error and continue
            completedCount++;
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Resource load was unsuccessful."
                                                                               withFailureReason:@"Object was not a NSString filename"
                                                                          withRecoverySuggestion:@"queryWithQuery: requires a NSString representing a resource"
                                                                             withRecoveryOptions:nil];
            topError = [NSError errorWithDomain:KCSResourceErrorDomain
                                           code:KCSPrecondFailedError
                                       userInfo:userInfo];
            
            if (completedCount == totalObjects) {
                completionBlock(completedObjects, topError);
            } 
        }
    }
}

#pragma mark - Removing
- (void)removeObject:(id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];
    int totalObjects = objectsToProcess.count;
    if (totalObjects == 0) {
        completionBlock(nil, nil);
    }
    
    __block int completedCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalObjects];
    __block NSError* topError = nil;
    
    for (id entity in objectsToProcess) {
        if ([entity isKindOfClass:[NSString class]]) {
            
            // This is where the work will be required...
            [KCSResourceService deleteResource:entity completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (errorOrNil != nil) {
                    topError = errorOrNil;
                }
                if (objectsOrNil != nil) {
                    [completedObjects addObjectsFromArray:objectsOrNil];
                }
                completedCount++;
                if (completedCount == totalObjects) {
                    completionBlock(completedObjects, topError);
                }
            } progressBlock:^(NSArray *objects, double percentComplete) {
                if (progressBlock != nil) {
                    progressBlock(objects, completedCount / (double) totalObjects + percentComplete /(double) totalObjects);
                }
            }];
        } else {
            //not a NSString (only accepted type in 1.4), generate error and continue
            completedCount++;
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Resource delete was unsuccessful."
                                                                               withFailureReason:@"Object was not a NSString filename"
                                                                          withRecoverySuggestion:@"remove: requires a NSString representing a resource"
                                                                             withRecoveryOptions:nil];
            topError = [NSError errorWithDomain:KCSResourceErrorDomain
                                           code:KCSPrecondFailedError
                                       userInfo:userInfo];
            
            if (completedCount == totalObjects) {
                completionBlock(completedObjects, topError);
            } 
        }
    }
}

#pragma mark - Configuring
- (BOOL)configureWithOptions: (NSDictionary *)options
{
    if (options) {
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}
//TODO: unit tests
@end
