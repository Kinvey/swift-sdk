
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
#import "NSString+KinveyAdditions.h"
#import "KCS_SBJsonWriter.h"
#import "KCSObjectMapper.h"

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
    return [self storeWithAuthHandler:nil withOptions:nil];
}

+ (id)storeWithOptions: (NSDictionary *)options
{
    return [self storeWithAuthHandler:nil withOptions:options];
}

+ (id)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSAppdataStore *store = [[[self alloc] initWithAuth:authHandler] autorelease];
    [store configureWithOptions:options];
    return store;
}

+ (id) storeWithCollection:(KCSCollection*)collection options:(NSDictionary*)options
{
    return [self storeWithCollection:collection authHandler:nil withOptions:options];    
}

+ (id)storeWithCollection:(KCSCollection*)collection authHandler:(KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options {
    
    if (options == nil) {
        options = [NSDictionary dictionaryWithObjectsAndKeys:collection, KCSStoreKeyResource, nil];
    } else {
        options= [NSMutableDictionary dictionaryWithDictionary:options];
        [options setValue:collection forKey:KCSStoreKeyResource];
    }
    return [self storeWithAuthHandler:authHandler withOptions:options];
}

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    if (options) {
        // Configure
        self.backingCollection = [options objectForKey:KCSStoreKeyResource];
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

- (BOOL) validatePreconditionsAndSendErrorTo:(void(^)(id objs, NSError* error))completionBlock
{
    if (completionBlock == nil) {
        return NO;
    }
    
    BOOL okay = YES;    
    KCSCollection* collection = self.backingCollection;
    if (collection == nil) {
        collection = NO;
        dispatch_async(dispatch_get_current_queue(), ^{
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"This store is not associated with a resource." 
                                                                               withFailureReason:@"Store's collection is nil"
                                                                          withRecoverySuggestion:@"Create a store with KCSCollection object for  'kKCSStoreKeyResource'."
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];
            
            completionBlock(nil, error);
        });
    }
    return okay;
}

#pragma mark - handling reponses
NSObject* parseJSON(NSData* data);
NSObject* parseJSON(NSData* data)
{
#if NEVER && NEW_KCS_BEHAVIOR_READY
    NSDictionary *jsonResponse = [data objectFromJSONData];
    NSObject *jsonData = [jsonResponse valueForKey:@"result"];
#else  
    KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
    NSObject *jsonData = [parser objectWithData:data];
    [parser release];
#endif 
    return jsonData;
}

#pragma mark - Querying/Fetching
- (void)loadObjectWithID: (id)objectID 
     withCompletionBlock: (KCSCompletionBlock)completionBlock
       withProgressBlock: (KCSProgressBlock)progressBlock;
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    KCSCollection* collection = self.backingCollection;
    NSArray* array = [NSArray wrapIfNotArray:objectID];
    if ([array containsObject:@""]) {
        dispatch_async(dispatch_get_current_queue(), ^{
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID." 
                                                                               withFailureReason:@"Object id cannot be empty."
                                                                          withRecoverySuggestion:nil
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
            completionBlock(nil, error);
        });
        return;
    }
    
    RestRequestForObjBlock_t requestBlock = ^KCSRESTRequest *(id obj) {
        NSString *resource = nil;
        // create a link: baas.kinvey.com/:appid/:collection/:id
        if ([collection.collectionName isEqualToString:@""]){
            resource = [collection.baseURL stringByAppendingFormat:@"%@", obj];
        } else {
            resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, obj];
        }
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
        [request setContentType:@"application/json"];        
        return request;
    };
    
    ProcessDataBlock_t processBlock = [self makeProcessBlock];
    
    [self operation:objectID RESTRequest:requestBlock dataHandler:processBlock completionBlock:completionBlock progressBlock:progressBlock];
}

- (void)queryWithQuery: (id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [self.backingCollection fetchWithQuery:query 
                       withCompletionBlock:completionBlock
                         withProgressBlock:progressBlock];
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    KCSCollection* collection = self.backingCollection;
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    NSString* collectionName = collection.collectionName;
    NSString *format = nil;
    
    if ([collectionName isEqualToString:@""]){
        format = @"%@_group";
    } else {
        format = @"%@/_group";
    }
    
    NSArray* fields = [NSArray wrapIfNotArray:fieldOrFields];
    
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

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self group:fieldOrFields reduce:function condition:[KCSQuery query] completionBlock:completionBlock progressBlock:progressBlock];
}

#pragma mark - Perform single entity objects on arrays
typedef KCSRESTRequest* (^RestRequestForObjBlock_t)(id obj);
typedef void (^ProcessDataBlock_t)(KCSConnectionResponse* response, KCSCompletionBlock completion);

- (void) operation:(id)object RESTRequest:(RestRequestForObjBlock_t)requestBlock dataHandler:(ProcessDataBlock_t)processBlock completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{    
    NSArray* objectsToOperateOn = [NSArray wrapIfNotArray:object];
    NSMutableArray* objectsToReturn = [NSMutableArray arrayWithCapacity:objectsToOperateOn.count];
    NSUInteger totalCount = objectsToOperateOn.count;
    __block NSUInteger outstandingCount = totalCount;
    
    __block NSError* topError = nil;
    [objectsToOperateOn enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        KCSConnectionCompletionBlock completionAction = ^(KCSConnectionResponse* response) {
            KCSLogTrace(@"In collection callback with response: %@", response);
            processBlock(response, ^(NSArray* objectsOrNil, NSError* error) {
                if (error != nil) {
                    topError = error;
                    if (self.treatSingleFailureAsGroupFailure == YES) {
                        *stop = YES;
                    }
                }
                [objectsToReturn addObjectsFromArray:objectsOrNil];
                
                if (*stop == YES || --outstandingCount == 0) {
                    completionBlock(objectsToReturn, error);
                }
                
            });
            
            
        };    
        
        KCSConnectionFailureBlock failureAction = ^(NSError* error) {
            topError = error;
            if (self.treatSingleFailureAsGroupFailure == YES) {
                *stop = YES;
            }
            if (*stop || --outstandingCount == 0) {
                completionBlock(objectsToReturn, error);
            }
        };
        
        KCSRESTRequest* request = requestBlock(obj);                     
        [[request withCompletionAction:completionAction failureAction:failureAction progressAction:^(KCSConnectionProgress* progress) {
            if (progressBlock != nil) {
                progressBlock(progress.objects, ((double) totalCount - 1) / ((double) idx + 1) + progress.percentComplete);
            }
        }] start];
    }];
}

- (ProcessDataBlock_t) makeProcessBlock
{
    ProcessDataBlock_t processBlock = ^(KCSConnectionResponse *response, KCSCompletionBlock completionBlock) {
        KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonResponse = [parser objectWithData:response.responseData];
#if NEVER && KCS_SUPPORTS_THIS_FEATURE
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        NSError* error = nil;
        if (response.responseCode != KCS_HTTP_STATUS_CREATED && response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Entity operation was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", responseToReturn]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                        code:[response responseCode]
                                    userInfo:userInfo];
            completionBlock(nil, error);
        } else {
            if (responseToReturn) {
                [self buildObjectFromJSON:responseToReturn withCompletionBlock:^(NSArray* objectsOrNil, NSError* errorOrNil){
                    completionBlock(objectsOrNil, errorOrNil);
                }];
                
            } else {
                completionBlock(nil, nil);
            }
        }
        // return returnVal;
    };
    return [[processBlock copy] autorelease];
}

#pragma mark - Adding/Updating
- (void) buildObjectFromJSON:(NSDictionary*)dictValue withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    completionBlock([NSArray arrayWithObject:[KCSObjectMapper makeObjectOfType:self.backingCollection.objectTemplate withData:dictValue]], nil);
}

- (void) saveEntity:(KCSSerializedObject*)serializedObj withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    RestRequestForObjBlock_t requestBlock = ^KCSRESTRequest *(id obj) {
        BOOL isPostRequest = serializedObj.isPostRequest;
        NSString *objectId = serializedObj.objectId;
        NSDictionary *dictionaryToMap = [serializedObj.dataToSerialize retain];
        
        KCSCollection* collection = self.backingCollection;
        NSString *resource = nil;
        if ([collection.collectionName isEqualToString:@""]){
            resource = [collection.baseURL stringByAppendingFormat:@"%@", objectId];        
        } else {
            resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];
        }
        
        // If we need to post this, then do so
        NSInteger HTTPMethod = (isPostRequest) ? kPostRESTMethod : kPutRESTMethod;
        
        // Prepare our request
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:HTTPMethod];
        
        // This is a JSON request
        [request setContentType:KCS_JSON_TYPE];
        
        // Make sure to include the UTF-8 encoded JSONData...
        KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
        [request addBody:[writer dataWithObject:dictionaryToMap]];
        [dictionaryToMap release];
        return request;
    };
    
    
    ProcessDataBlock_t processBlock = [self makeProcessBlock];
    
    KCSConnectionCompletionBlock completionAction = ^(KCSConnectionResponse* response) {
        KCSLogTrace(@"In collection callback with response: %@", response);
        processBlock(response, completionBlock);
    };    
    
    KCSConnectionFailureBlock failureAction = ^(NSError* error) {
        completionBlock(nil, error);
    };
    
    KCSRESTRequest* request = requestBlock(nil);                     
    [[request withCompletionAction:completionAction failureAction:failureAction progressAction:^(KCSConnectionProgress* progress) {
        if (progressBlock != nil) {
            progressBlock(progress.objects, progress.percentComplete);
        }
    }] start];    
}

- (void)saveObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    NSArray* objectsToSave = [NSArray wrapIfNotArray:object];
    if (objectsToSave.count == 0) {
        completionBlock(nil, nil);
        return;
    }
    
    int totalItemCount = [objectsToSave count];
    
    __block int completedItemCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalItemCount];
    
    
    __block NSError* topError = nil;
    __block BOOL done = NO;
    for (id <KCSPersistable> singleEntity in objectsToSave) {
        KCSSerializedObject* serializedObj = [KCSObjectMapper makeKinveyDictionaryFromObject:singleEntity];
        
        [self saveEntity:serializedObj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
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

#pragma mark - Removing

- (void)removeObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];   
    if (objectsToProcess.count == 0) {
        completionBlock(nil, nil);
        return;
    }
    
    NSMutableArray* outstandingObjects = [NSMutableArray arrayWithArray:objectsToProcess];
    
    int totalItemCount = [outstandingObjects count];
    __block int completedItemCount = 0;
    __block BOOL done = NO;
    __block 
    
    NSMutableArray* returnedObjects = [NSMutableArray arrayWithCapacity:totalItemCount];
    __block NSError* topError = nil;
    
    for (NSObject* entity in objectsToProcess) {
        [entity deleteFromCollection:self.backingCollection withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (done) {
                //don't do the completion blocks for all the objects if its previously finished
                return;
            }
            if (errorOrNil != nil) {
                topError = errorOrNil;
            }
            if (errorOrNil != nil && self.treatSingleFailureAsGroupFailure == YES) {
                done = YES;
            }
            if (objectsOrNil != nil) {
                [returnedObjects addObjectsFromArray:objectsOrNil];
            }
            completedItemCount++;
            if (done || completedItemCount == totalItemCount) {
                completionBlock(returnedObjects, topError);
            }
            
        } withProgressBlock:^(NSArray* objectsOrNil, double percentComplete) {
            progressBlock(objectsOrNil, completedItemCount/(double) totalItemCount + percentComplete * 1 / (double) totalItemCount);
            
        }];
        
    }
}
/* TO ENABLE WHEN $IN supported for _id
- (void) removeObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return;
    }
    
    NSArray *objectsToProcess = [NSArray wrapIfNotArray:object];   
    if (objectsToProcess.count == 0) {
        completionBlock(nil, nil);
        return;
    }
    
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:objectsToProcess.count];
    [objectsToProcess enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary* mapping = [obj hostToKinveyPropertyMapping];
        NSSet* set = [mapping keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            return [obj isEqualToString:@"_id"];
        }];
        NSString* objname = set.count == 0 ? nil: [object valueForKey:[set anyObject]];
        if (objname) {
            [ids addObject:objname];
        }
    }];
    
    KCSQuery* deleteQuery = [KCSQuery queryOnField:@"_id" usingConditional:kKCSIn forValue:ids];
    NSString *resource = nil;
    NSString *format = nil;
    
    KCSCollection* collection = self.backingCollection;
    if ([collection.collectionName isEqualToString:@""]){
        format = @"%@";
    } else {
        format = @"%@/";
    }
    
    resource = [collection.baseURL stringByAppendingFormat:format, collection.collectionName];
    
    // Add the Query portion of the request
    if (deleteQuery.query != nil && deleteQuery.query.count > 0){
        resource = [resource stringByAppendingQueryString:[deleteQuery parameterStringRepresentation]];
    }
    
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kDeleteRESTMethod];
    
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        
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
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Deletion was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", jsonData]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            completionBlock(nil, error);
            
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
        
        completionBlock(jsonArray, nil);
        [processedData release];
    };
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        completionBlock(nil, error);
    };
    KCSConnectionProgressBlock pBlock = makeProgressBlock(progressBlock);
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}
*/
#pragma mark - Information
- (void)countWithBlock:(KCSCountBlock)countBlock
{
    [self.backingCollection entityCountWithBlock:countBlock];
}


@end
