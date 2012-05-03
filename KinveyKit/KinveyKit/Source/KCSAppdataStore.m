//
//  KCSAppdataStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSAppdataStore.h"
#import "KinveyPersistable.h"
#import "KinveyCollection.h"
#import "KinveyEntity.h"
#import "KCSBlockDefs.h"

@interface KCSAppdataStore ()

@property (nonatomic) BOOL treatSingleFailureAsGroupFailure;
@property (nonatomic, retain) KCSCollection *backingCollection;

@end


@implementation KCSAppdataStore

@synthesize authHandler = _authHandler;
@synthesize treatSingleFailureAsGroupFailure = _treatSingleFailureAsGroupFailure;
@synthesize backingCollection = _backingCollection;


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
        _treatSingleFailureAsGroupFailure = YES;
    }
    return self;
}

+ (id)store
{
    return [KCSAppdataStore storeWithAuthHandler:nil withOptions:nil];
}

+ (id)storeWithOptions: (NSDictionary *)options
{
    return [KCSAppdataStore storeWithAuthHandler:nil withOptions:options];
}

+ (id)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSAppdataStore *store = [[[KCSAppdataStore alloc] initWithAuth:authHandler] autorelease];

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
        if (![entity conformsToProtocol:@protocol(KCSPersistable)]){
            // Error processing
            // Handle the error
            
            if (self.treatSingleFailureAsGroupFailure){
                // Stop processing and just fail out
                break;
            } else {
                // Perform the rest of the operations
                continue;
            }
        }
        
        // This is where the work will be required...
        [entity saveToCollection:self.backingCollection
             withCompletionBlock:completionBlock
               withProgressBlock:progressBlock];
    }
}

#pragma mark -
#pragma mark Querying/Fetching
- (void)queryWithQuery: (id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [self.backingCollection fetchWithQuery:query 
                       withCompletionBlock:completionBlock
                         withProgressBlock:progressBlock];
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
        if (![entity conformsToProtocol:@protocol(KCSPersistable)]){
            // Error processing
            // Handle the error
            
            if (self.treatSingleFailureAsGroupFailure){
                // Stop processing and just fail out
                break;
            } else {
                // Perform the rest of the operations
                continue;
            }
        }
        
        // This is where the work will be required...
        [entity deleteFromCollection:self.backingCollection
                 withCompletionBlock:completionBlock
                   withProgressBlock:progressBlock];
    }

}

#pragma mark -
#pragma mark Information
- (void)countWithBlock:(KCSCountBlock)countBlock
{
    
}


#pragma mark -
#pragma mark Configuring
- (BOOL)configureWithOptions: (NSDictionary *)options
{
    if (options) {
        // Configure
        self.backingCollection = [options objectForKey:@"resource"];
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}


#pragma mark -
#pragma mark Authentication


@end
