//
//  KinveyCollection.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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


#import "KinveyPersistable.h"
#import "KinveyCollection.h"
#import "KCSClient.h"
#import "NSString+KinveyAdditions.h"
#import "KCSRESTRequest.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCSConnectionResponse.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "KCSObjectMapper.h"
#import "KCSQuery.h"
#import "KCSStore.h"
#import "KCSBlockDefs.h"
#import "KCSConnectionProgress.h"
#import "KinveyUser.h"
#import "KCSClientConfiguration.h"

#import "KCSRequest2.h"

NSString* const KCSUserCollectionName = @"user";

typedef enum KCSCollectionCategory : NSInteger {
    KCSCollectionAppdata, KCSCollectionUser, KCSCollectionBlob
} KCSCollectionCategory;

// Avoid compiler warning by prototyping here...
KCSConnectionCompletionBlock makeCollectionCompletionBlock(KCSCollection *collection,
                                                           id<KCSCollectionDelegate>delegate,
                                                           KCSCompletionBlock onComplete);

KCSConnectionFailureBlock    makeCollectionFailureBlock(KCSCollection *collection,
                                                        id<KCSCollectionDelegate>delegate,
                                                        KCSCompletionBlock onComplete);

KCSConnectionProgressBlock   makeCollectionProgressBlock(KCSCollection *collection,
                                                         id<KCSCollectionDelegate>delegate,
                                                         KCSProgressBlock onProgress);

KCSConnectionCompletionBlock makeCollectionCompletionBlock(KCSCollection *collection,
                                                           id<KCSCollectionDelegate>delegate,
                                                           KCSCompletionBlock onComplete)
{
    return [^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        NSMutableArray *processedData = [[NSMutableArray alloc] init];
        
        NSObject* jsonData = [response jsonResponseValue];
        NSArray *jsonArray = nil;
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:(NSDictionary*) jsonData description:@"Collection fetch was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
            if (delegate){
                [delegate collection:collection didFailWithError:error];
            } else {
                onComplete(nil, error);
            }
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
        
        for (NSDictionary *dict in jsonArray) {
            [processedData addObject:[KCSObjectMapper makeObjectOfType:collection.objectTemplate withData:dict]];
        }
        if (delegate){
            [delegate collection:collection didCompleteWithResult:processedData];
        } else {
            onComplete(processedData, nil);
        }
    } copy];
}

KCSConnectionFailureBlock    makeCollectionFailureBlock(KCSCollection *collection,
                                                        id<KCSCollectionDelegate>delegate,
                                                        KCSCompletionBlock onComplete)
{
    if (delegate){
        return [^(NSError *error){
            [delegate collection:collection didFailWithError:error];
        } copy];
    } else {
        return [^(NSError *error){
            onComplete(nil, error);
        } copy];
    }
}

KCSConnectionProgressBlock   makeCollectionProgressBlock(KCSCollection *collection,
                                                         id<KCSCollectionDelegate>delegate,
                                                         KCSProgressBlock onProgress)
{
    
    return [^(KCSConnectionProgress *conn)
            {
                if (onProgress != nil) {
                    //TODO: deprecate
                    onProgress(@[], conn.percentComplete);
                }
            } copy];
    
}

@interface KCSCollection ()
@property (nonatomic) KCSCollectionCategory category;

@end


@implementation KCSCollection

// Usage concept
// In controller
// self.objectCollection = [[KCSCollection alloc] init];
// self.objectCollection.collectionName = @"lists";
// self.objectColleciton.objectTemplate = [[MyObject alloc] init];
// self.objectCollection.kinveyConnection = [globalConnection];
//
// And later...
// [self.objectCollection collectionDelegateFetchAll: ()

- (id)initWithName: (NSString *)name forTemplateClass: (Class) theClass
{
    self = [super init];
    
    if (self){
        if ([name isEqualToString:KCSUserCollectionName]) {
            //remove this in the wake fo KCSUser2 & KCSUser2 subclasses
//            if ([theClass isSubclassOfClass:[KCSUser class]] == NO) {
//                [[NSException exceptionWithName:@"Invalid Template" reason:@"User collection must have a template that is of type 'KCSUser'" userInfo:nil] raise];
//            }
            _category = KCSCollectionUser;
        } else if ([name isEqualToString:@"_blob"]) {
            _category = KCSCollectionBlob;
        } else {
            _category = KCSCollectionAppdata;
        }
        _collectionName = name;
        _objectTemplate = theClass;
        _lastFetchResults = nil;
        _query = nil;
    }
    
    return self;
}


- (id)init
{
    return [self initWithName:nil forTemplateClass:[NSMutableDictionary class]];
}



// Override isEqual method to allow comparing of Collections
// A collection is equal if the name, object template and filter are the same
- (BOOL) isEqual:(id)object
{
    KCSCollection *c = (KCSCollection *)object;
    
    if (![object isKindOfClass:[self class]]){
        return NO;
    }
    
    if (![self.collectionName isEqualToString:c.collectionName]){
        return NO;
    }
    
    if (![c.objectTemplate isEqual:c.objectTemplate]){
        return NO;
    }
    
    return YES;
}



+ (KCSCollection *)collectionFromString: (NSString *)string ofClass: (Class)templateClass
{
    KCSCollection *collection = [[self alloc] initWithName:string forTemplateClass:templateClass];
    return collection;
}


#pragma mark Basic Methods
- (NSString*) baseURL
{
    NSString* baseURL = nil;
    switch (_category) {
        case KCSCollectionUser:
            baseURL = [[KCSClient sharedClient] userBaseURL]; /*use user url for user collection*/
            break;
        case KCSCollectionBlob:
            baseURL = [[KCSClient sharedClient] resourceBaseURL]; /*use blob url*/
            break;
        case KCSCollectionAppdata:
        default:
            baseURL = [[KCSClient sharedClient] appdataBaseURL]; /* Initialize this to the default appdata URL*/
            break;
    }
    DBAssert(baseURL != nil, @"Should have a base url for the collection %@", _collectionName);
    return baseURL;
}

- (NSString*) urlForEndpoint:(NSString*)endpoint
{
    if (endpoint == nil) {
        endpoint = @"";
    }
    
    NSString *resource = nil;
    // create a link: baas.kinvey.com/:appid/:collection/:id
    if ([self.collectionName isEqualToString:@""]){
        resource = [self.baseURL stringByAppendingFormat:@"%@", endpoint];
    } else {
        resource = [self.baseURL stringByAppendingFormat:@"%@/%@", self.collectionName, endpoint];
    }
    return resource;
}

- (KCSRESTRequest*)restRequestForMethod:(KCSRESTMethod)method apiEndpoint:(NSString*)endpoint
{
    NSString *resource = [self urlForEndpoint:endpoint];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:method];
    [request setContentType:KCS_JSON_TYPE];
    return request;
}


- (void)fetchAllWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    NSString *resource = [self.baseURL stringByAppendingFormat:@"%@/", self.collectionName];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = makeCollectionCompletionBlock(self, delegate, nil);
    KCSConnectionFailureBlock fBlock = makeCollectionFailureBlock(self, delegate, nil);
    KCSConnectionProgressBlock pBlock = makeCollectionProgressBlock(self, delegate, nil);
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (void)fetchWithQuery:(KCSQuery *)query withCompletionBlock:(KCSCompletionBlock)onCompletion withProgressBlock:(KCSProgressBlock)onProgress
{
    NSString *resource = nil;
    NSString *format = nil;
    
    if ([self.collectionName isEqualToString:@""]){
        format = @"%@";
    } else {
        format = @"%@/";
    }
    
    // Here we know that we're working with a query, so now we just check each of the params...
    if (query != nil){
        resource = [self.baseURL stringByAppendingFormat:format, self.collectionName];
        resource = [resource stringByAppendingString:[query parameterStringRepresentation]];
    }
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    
    KCSConnectionCompletionBlock cBlock = makeCollectionCompletionBlock(self, nil, onCompletion);
    KCSConnectionFailureBlock fBlock = makeCollectionFailureBlock(self, nil, onCompletion);
    KCSConnectionProgressBlock pBlock = makeCollectionProgressBlock(self, nil, onProgress);
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
    
}



- (void)fetchWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    // Guard against an empty filter
    if (self.query == nil){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to fetch with an empty query."
                                                                           withFailureReason:@"No query or filter was supplied to fetchWithDelegate:"
                                                                      withRecoverySuggestion:@"Provide a query or filter, or use fetchAllWithDelegate:"
                                                                         withRecoveryOptions:nil];
        NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                             code:KCSInvalidArgumentError
                                         userInfo:userInfo];
        
        [delegate collection:self didFailWithError:error];
        return;
    }
    
    NSString *resource = nil;
    NSString *format = nil;
    
    if ([self.collectionName isEqualToString:@""]){
        format = @"%@";
    } else {
        format = @"%@/";
    }
    
    // Here we know that we're working with a query, so now we just check each of the params...
    resource = [self.baseURL stringByAppendingFormat:format, self.collectionName];
    resource = [resource stringByAppendingString:[self.query parameterStringRepresentation]];
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    
    KCSConnectionCompletionBlock cBlock = makeCollectionCompletionBlock(self, delegate, nil);
    KCSConnectionFailureBlock fBlock = makeCollectionFailureBlock(self, delegate, nil);
    KCSConnectionProgressBlock pBlock = makeCollectionProgressBlock(self, delegate, nil);
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

#pragma mark Utility Methods

- (void)entityCountWithDelegate:(id<KCSInformationDelegate>)delegate
{
    NSString *resource = [self urlForEndpoint:@"_count"];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary* jsonResponse = (NSDictionary*) [response jsonResponseValue];
        
        int count;
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Information request  was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
            
            [delegate collection:self informationOperationFailedWithError:error];
            return;
        }
        
        NSString *val = [jsonResponse valueForKey:@"count"];
        
        if (val){
            count = [val intValue];
        } else {
            count = 0;
        }
        [delegate collection:self informationOperationDidCompleteWithResult:count];
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate collection:self informationOperationFailedWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *collection) {};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

-(void)entityCountWithBlock:(KCSCountBlock)countBlock
{
    NSString *resource = [self urlForEndpoint:@"_count"];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonResponse = (NSDictionary*) [response jsonResponseValue];
        int count;
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Information request  was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
            countBlock(0, error);
            return;
        }
        
        NSString *val = [jsonResponse valueForKey:@"count"];
        
        if (val){
            count = [val intValue];
        } else {
            count = 0;
        }
        countBlock(count, nil);
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        countBlock(0, error);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *collection) {};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

// AVG is not in the REST docs anymore

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"KCSCollection: %@", _collectionName];
}

#pragma mark - User collection
+ (instancetype) userCollection
{
    Class userClass = [KCSClient sharedClient].configuration.options[KCS_USER_CLASS];
    if (!userClass) {
        userClass = [KCSUser class];
    }
    return [self collectionFromString:KCSUserCollectionName ofClass:userClass];
}


#pragma mark - KinveyKit2
- (NSString*) route
{
    NSString* route = KCSRESTRouteAppdata;
    if ([_collectionName isEqualToString:KCSUserCollectionName]) {
        route = KCSRESTRouteUser;
    } else if ([_collectionName isEqualToString:@"_blob"]) {
        route = KCSRESTRouteBlob;
    }
    return route;
}
@end
