//
//  KinveyCollection.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
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
    return [[^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        NSMutableArray *processedData = [[NSMutableArray alloc] init];

        NSObject* jsonData = [response jsonResponseValue];
        NSArray *jsonArray = nil;
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:(NSDictionary*) jsonData description:@"Collection fetch was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain];
            if (delegate){
                [delegate collection:collection didFailWithError:error];
            } else {
                onComplete(nil, error);
            }

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
        
        for (NSDictionary *dict in jsonArray) {
            [processedData addObject:[KCSObjectMapper makeObjectOfType:collection.objectTemplate withData:dict]];
        }
        if (delegate){
            [delegate collection:collection didCompleteWithResult:processedData];
        } else {
            onComplete(processedData, nil);
        }
        [processedData release];
    } copy] autorelease];
}

KCSConnectionFailureBlock    makeCollectionFailureBlock(KCSCollection *collection,
                                                        id<KCSCollectionDelegate>delegate,
                                                        KCSCompletionBlock onComplete)
{
    if (delegate){
        return [[^(NSError *error){
            [delegate collection:collection didFailWithError:error];
        } copy] autorelease];
    } else {
        return [[^(NSError *error){
            onComplete(nil, error);
        } copy] autorelease];        
    }
}

KCSConnectionProgressBlock   makeCollectionProgressBlock(KCSCollection *collection,
                                                         id<KCSCollectionDelegate>delegate,
                                                         KCSProgressBlock onProgress)
{
    
    return [[^(KCSConnectionProgress *conn)
    {
        if (onProgress != nil) {
            onProgress(conn.objects, conn.percentComplete);
        }
    } copy] autorelease];
    
}




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

@synthesize collectionName=_collectionName;
@synthesize objectTemplate=_objectTemplate;
@synthesize lastFetchResults=_lastFetchResults;
@synthesize filters=_filters;
@synthesize baseURL = _baseURL;
@synthesize query = _query;

- (id)initWithName: (NSString *)name forTemplateClass: (Class) theClass
{
    self = [super init];
    
    if (self){
        if ([name isEqualToString:KCSUserCollectionName]) {
            if ([theClass isSubclassOfClass:[KCSUser class]] == NO) {
                [[NSException exceptionWithName:@"Invalid Template" reason:@"User collection must have a template that is of type 'KCSUser'" userInfo:nil] raise];
            }
            _collectionName = @"";
            _baseURL = [[[KCSClient sharedClient] userBaseURL] retain]; //use user url for user collection
        } else {
            _collectionName = [name retain];
            _baseURL = [[[KCSClient sharedClient] appdataBaseURL] retain]; // Initialize this to the default appdata URL
        }
        _objectTemplate = theClass;
        _lastFetchResults = nil;
        _filters = [[NSMutableArray alloc] init];
        _query = nil;
    }
    
    return self;
}


- (id)init
{
    return [self initWithName:nil forTemplateClass:[NSObject class]];
}

- (void)dealloc
{
    [_filters release];
    [_lastFetchResults release];
    [_collectionName release];
    [_baseURL release];
    [_query release];
    [super dealloc];
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
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (![self.filters isEqualToArray:c.filters]){
        return NO;
    }
#pragma clang diagnostic pop
    
    return YES;
}



+ (KCSCollection *)collectionFromString: (NSString *)string ofClass: (Class)templateClass
{
    KCSCollection *collection = [[[self alloc] initWithName:string forTemplateClass:templateClass] autorelease];
    return collection;
}


#pragma mark Basic Methods
- (KCSRESTRequest*)restRequestForMethod:(KCSRESTMethod)method apiEndpoint:(NSString*)endpoint
{
    NSString *resource = nil;
    // create a link: baas.kinvey.com/:appid/:collection/:id
    if ([self.collectionName isEqualToString:@""]){
        resource = [self.baseURL stringByAppendingFormat:@"%@", endpoint];
    } else {
        resource = [self.baseURL stringByAppendingFormat:@"%@/%@", self.collectionName, endpoint];
    }
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

// Private class helper method...
+ (NSString *)getOperatorString: (int)op
{
    switch (op) {
        case KCS_EQUALS_OPERATOR:
            return nil;
            break;
        case KCS_LESS_THAN_OPERATOR:
            return @"$lt";
            break;
        case KCS_GREATER_THAN_OPERATOR:
            return @"$gt";
            break;
        case KCS_LESS_THAN_OR_EQUAL_OPERATOR:
            return @"$lte";
            break;
        case KCS_GREATER_THAN_OR_EQUAL_OPERATOR:
            return @"$gte";
            break;
            
        default:
            return nil;
            break;
    }
}

- (NSString *)buildQueryForProperty: (NSString *)property withValue: (id)value filteredByOperator: (int)op
{
    NSString *query;
    
    NSString *stringValue;
    
    // Check to see if the object is a string or a real object
    // surround strings with quotes, values without
    if ([value isKindOfClass:[NSString class]]){
        stringValue = [NSString stringWithFormat:@"\"%@\"", value];
    } else {
        stringValue = [NSString stringWithFormat:@"%@", value];
    }
    
    if (op == KCS_EQUALS_OPERATOR){
        query = [NSString stringWithFormat:@"\"%@\": %@", property, stringValue];
    } else {
        query = [NSString stringWithFormat:@"\"%@\": {\"%@\": %@}", property, [KCSCollection getOperatorString:op], stringValue];
    }
    return query;
    
}

- (NSString *)buildQueryForFilters: (NSArray *)filters
{
    NSString *outputString = @"{";
    for (NSString *filter in filters) {
        outputString = [outputString stringByAppendingFormat:@"%@, ", filter];
    }
    
    // String the trailing ','
    if ([outputString characterAtIndex:[outputString length]-2] == ','){
        outputString = [outputString substringToIndex:[outputString length] -2];
    }
    
    return [outputString stringByAppendingString:@"}"];
}


#pragma mark Query Methods
- (void)addFilterCriteriaForProperty: (NSString *)property withBoolValue: (BOOL) value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
}

- (void)addFilterCriteriaForProperty: (NSString *)property withDoubleValue: (double)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
	
}

- (void)addFilterCriteriaForProperty: (NSString *)property withIntegerValue: (int)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
	
}

- (void)addFilterCriteriaForProperty: (NSString *)property withStringValue: (NSString *)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:value filteredByOperator:operator]];
	
}

- (void)resetFilterCriteria
{
    [self.filters removeAllObjects];
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
        resource = [resource stringByAppendingString:[self.query parameterStringRepresentation]];
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
    if (_filters.count == 0 && self.query == nil){
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
    if (self.query != nil){
        resource = [self.baseURL stringByAppendingFormat:format, self.collectionName];

        resource = [resource stringByAppendingString:[self.query parameterStringRepresentation]];
    } else {
        resource = [self.baseURL stringByAppendingFormat:format, self.collectionName];
        resource = [resource stringByAppendingQueryString:[NSString stringWithFormat:@"query=%@", [NSString stringByPercentEncodingString:[self buildQueryForFilters:_filters]]]];
    }

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
    NSString *resource = nil;
    if ([self.collectionName isEqualToString:@""]){
        resource = [self.baseURL stringByAppendingFormat:@"%@", @"_count"];        
    } else {
        resource = [self.baseURL stringByAppendingFormat:@"%@/%@", _collectionName, @"_count"];
    }
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary* jsonResponse = (NSDictionary*) [response jsonResponseValue];

        int count;

        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Information request  was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain];
            
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
    NSString *resource = nil;
    if ([self.collectionName isEqualToString:@""]){
        resource = [self.baseURL stringByAppendingFormat:@"%@", @"_count"];        
    } else {
        resource = [self.baseURL stringByAppendingFormat:@"%@/%@", _collectionName, @"_count"];
    }
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonResponse = (NSDictionary*) [response jsonResponseValue];
        int count;
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Information request  was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain];
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
+ (KCSCollection*) userCollection
{
    return [self collectionFromString:KCSUserCollectionName ofClass:[KCSUser class]];
}

@end
