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

#import "KCSQuery.h"
#import "KCSGroup.h"
#import "KCSReduceFunction.h"

#import "KCS_SBJsonParser.h"
#import "KCSRESTRequest.h"
#import "KCSConnectionResponse.h"
#import "KCSLogManager.h"
#import "KinveyHTTPStatusCodes.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSConnectionProgress.h"

#import "NSArray+KinveyAdditions.h"
#import "KCS_SBJsonWriter.h"

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

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    if (options) {
        // Configure
        self.backingCollection = [options objectForKey:kKCSStoreKeyResource];
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}

#pragma mark - Block Making
// Avoid compiler warning by prototyping here...
KCSConnectionCompletionBlock makeGroupCompletionBlock(KCSGroupCompletionBlock onComplete, NSString* key, NSArray* fields);
KCSConnectionFailureBlock    makeGroupFailureBlock(KCSGroupCompletionBlock onComplete);
KCSConnectionProgressBlock   makeProgressBlock(KCSProgressBlock onProgress);

KCSConnectionCompletionBlock makeGroupCompletionBlock(KCSGroupCompletionBlock onComplete, NSString* key, NSArray* fields)
{
    return [[^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        NSMutableArray *processedData = [[NSMutableArray alloc] init];
        
        // New KCS behavior, not ready yet
#if NEVER && KCS_NEW_BEHAVIOR_READY
        NSDictionary *jsonResponse = [response.responseData objectFromJSONData];
        NSObject *jsonData = [jsonResponse valueForKey:@"result"];
#else  
        KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
        NSObject *jsonData = [parser objectWithData:response.responseData];
        [parser release];
#endif        
        NSArray *jsonArray;
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Collection grouping was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", jsonData]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            onComplete(nil, error);
            
            [processedData release];
            return;
        }
        
        if ([jsonData isKindOfClass:[NSArray class]]){
            jsonArray = (NSArray *)jsonData;
        } else {
            if ([(NSDictionary *)jsonData count] == 0){
                jsonArray = [NSArray array];
            } else {
                jsonArray = [NSArray arrayWithObjects:(NSDictionary *)jsonData, nil];
            }
        }
        
        KCSGroup* group = [[[KCSGroup alloc] initWithJsonArray:jsonArray valueKey:key queriedFields:fields] autorelease];
        
        onComplete(group, nil);
        [processedData release];
    } copy] autorelease];
}

KCSConnectionFailureBlock makeGroupFailureBlock(KCSGroupCompletionBlock onComplete)
{
    return [[^(NSError *error){
        onComplete(nil, error);
    } copy] autorelease];        
}

KCSConnectionProgressBlock makeProgressBlock(KCSProgressBlock onProgress)
{
    return onProgress == nil ? nil : [[^(KCSConnectionProgress *connectionProgress) {
        onProgress(connectionProgress.objects, connectionProgress.percentComplete);
    } copy] autorelease];
}

#pragma mark - Querying/Fetching
- (void)queryWithQuery: (id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [self.backingCollection fetchWithQuery:query 
                       withCompletionBlock:completionBlock
                         withProgressBlock:progressBlock];
}

- (void)group:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    KCSCollection* collection = self.backingCollection;
    if (collection == nil) {
        dispatch_async(dispatch_get_current_queue(), ^{
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"This store is not associated with a resource." 
                                                                               withFailureReason:@"Store's collection is nil"
                                                                          withRecoverySuggestion:@"Create a store with a 'kKCSStoreKeyResource'."
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];

            completionBlock(nil, error);
        });
        return;
    }
    
    NSString* collectionName = self.backingCollection.collectionName;
    NSString *format = nil;
    
    if ([collectionName isEqualToString:@""]){
        format = @"%@_group";
    } else {
        format = @"%@/_group";
    }
    
    NSString *resource = [collection.baseURL stringByAppendingFormat:format, collectionName];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:4];
    NSMutableDictionary *keys = [NSMutableDictionary dictionaryWithCapacity:[fields count]];
    for (NSString* field in fields) {
        [keys setObject:[NSNumber numberWithBool:YES] forKey:field];
    }
    [body setObject:keys forKey:@"key"];
    [body setObject:[function JSONStringRepresentationForInitialValue:fields] forKey:@"initial"];
    [body setObject:[function JSONStringRepresentationForFunction:fields] forKey:@"reduce"];

    if (condition != nil) {
        [body setObject:[condition query] forKey:@"condition"];
    }
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kPostRESTMethod];
    KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
    [request addBody:[writer dataWithObject:body]];
    [request setContentType:@"application/json"];
    
    KCSConnectionCompletionBlock cBlock = makeGroupCompletionBlock(completionBlock, [function outputValueName:fields], fields);
    KCSConnectionFailureBlock fBlock = makeGroupFailureBlock(completionBlock);
    KCSConnectionProgressBlock pBlock = makeProgressBlock(progressBlock);
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start]; 
}

- (void)group:(NSArray *)fields reduce:(KCSReduceFunction *)function completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self group:fields reduce:function condition:[KCSQuery query] completionBlock:completionBlock progressBlock:progressBlock];
}

#pragma mark - Perform single entity objects on arrays
- (void) perform:(void (^)(id entity, KCSCompletionBlock completionBlock, KCSProgressBlock progressBlock))actionBlock onNext:(NSMutableArray*)outstandingObjects prevComplete:(double)prevComplete count:(double)totalCount withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    __block NSError* error = nil;
    if ([outstandingObjects count] > 0) {
        id entity = [outstandingObjects objectAtIndex:0];
        if (![entity conformsToProtocol:@protocol(KCSPersistable)]){
            // Error processing
            // Handle the error
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Supplied entity was not a KCSPersistable" 
                                                                               withFailureReason:[NSString stringWithFormat:@"class '%@' does not implement KCSPersistable protocol", [entity class]]
                                                                          withRecoverySuggestion:@"Implement KCSPersistable protocol"
                                                                             withRecoveryOptions:nil];
            error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSBadRequestError userInfo:userInfo];
            if (self.treatSingleFailureAsGroupFailure){
                // Stop processing and just fail out
                [outstandingObjects removeAllObjects];
            }
        } else {
            dispatch_async(dispatch_get_current_queue(), ^{
                KCSCompletionBlock thisCompletion = ^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    [outstandingObjects removeObject:entity];
                    if (errorOrNil != nil) {
                        error = errorOrNil;
                        if (self.treatSingleFailureAsGroupFailure) {
                            [outstandingObjects removeAllObjects];
                        }
                    } 
                    [self perform:actionBlock onNext:outstandingObjects prevComplete:prevComplete+1 count:totalCount withCompletionBlock:completionBlock withProgressBlock:progressBlock];
                };
                KCSProgressBlock thisProgress = ^(NSArray *objects, double percentComplete) {
                    progressBlock(objects, (prevComplete + percentComplete) / totalCount);
                };
                
                actionBlock(entity, thisCompletion, thisProgress);
            });
        }
    }
    
    if ([outstandingObjects count] == 0) {
        completionBlock(nil, error);
    }
}

#pragma mark - Adding/Updating
- (void)saveObject: (id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];
    double totalCount = objectsToProcess.count;
    
    NSMutableArray* outstandingObjects = [NSMutableArray arrayWithArray:objectsToProcess];
    [self perform:^(id entity, KCSCompletionBlock completionBlock, KCSProgressBlock progressBlock) {
        [entity saveToCollection:self.backingCollection withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } onNext:outstandingObjects prevComplete:0 count:totalCount withCompletionBlock:completionBlock withProgressBlock:progressBlock];
}

#pragma mark - Removing
- (void)removeObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];
    double totalCount = objectsToProcess.count;
    
    NSMutableArray* outstandingObjects = [NSMutableArray arrayWithArray:objectsToProcess];
    [self perform:^(id entity, KCSCompletionBlock completionBlock, KCSProgressBlock progressBlock) {
        [entity deleteFromCollection:self.backingCollection withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } onNext:outstandingObjects prevComplete:0 count:totalCount withCompletionBlock:completionBlock withProgressBlock:progressBlock];
}

#pragma mark - Information
- (void)countWithBlock:(KCSCountBlock)countBlock
{
    [self.backingCollection entityCountWithBlock:countBlock];
}


#pragma mark -
#pragma mark Authentication


@end
