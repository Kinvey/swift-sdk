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

+ (id)store
{
    return [KCSResourceStore storeWithAuthHandler:nil withOptions:nil];
}

+ (id)storeWithOptions: (NSDictionary *)options
{
    return [KCSResourceStore storeWithAuthHandler:nil withOptions:options];
}

+ (id)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSResourceStore *store = [[[KCSResourceStore alloc] initWithAuth:authHandler] autorelease];
    
    [store configureWithOptions:options];
    
    return store;
}


#pragma mark -
#pragma mark Adding/Updating
- (void)saveObject: (id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess;
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if (![object isKindOfClass:[NSArray class]]){
        objectsToProcess = [NSArray arrayWithObject:object];
    } else {
        objectsToProcess = object;
    }
    
    for (id entity in objectsToProcess) {
        if (![entity isKindOfClass:[NSURL class]]){
            // Error processing
            // Handle the error
                break;
        }
        
        // This is where the work will be required...
        [KCSResourceService saveLocalResourceWithURL:entity
                                     completionBlock:completionBlock
                                       progressBlock:progressBlock];
    }
}

#pragma mark -
#pragma mark Querying/Fetching
- (void)queryWithQuery: (id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess;
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if (![query isKindOfClass:[NSArray class]]){
        objectsToProcess = [NSArray arrayWithObject:query];
    } else {
        objectsToProcess = query;
    }
    
    for (id entity in objectsToProcess) {
        if (![entity isKindOfClass:[NSString class]]){
            // Error processing
            // Handle the error
            break;
        }
        
        // This is where the work will be required...
        [KCSResourceService downloadResource:entity completionBlock:completionBlock progressBlock:progressBlock];
    }

}

#pragma mark -
#pragma mark Removing
- (void)removeObject: (id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess;
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if (![object isKindOfClass:[NSArray class]]){
        objectsToProcess = [NSArray arrayWithObject:object];
    } else {
        objectsToProcess = object;
    }
    
    for (id entity in objectsToProcess) {
        if (![entity isKindOfClass:[NSString class]]){
            // Error processing
            // Handle the error
            break;
        }
        
        // This is where the work will be required...
        [KCSResourceService deleteResource:entity completionBlock:completionBlock progressBlock:progressBlock];
    }
}

#pragma mark -
#pragma mark Information
- (void)countWithBlock:(KCSCountBlock)countBlock
{
    countBlock(0, nil);
}


#pragma mark -
#pragma mark Configuring
- (BOOL)configureWithOptions: (NSDictionary *)options
{
    if (options) {
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}


#pragma mark -
#pragma mark Authentication


@end
