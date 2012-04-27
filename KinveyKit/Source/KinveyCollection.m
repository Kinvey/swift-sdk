//
//  KinveyCollection.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyPersistable.h"
#import "KinveyCollection.h"
#import "KCSClient.h"
#import "NSString+KinveyAdditions.h"
#import "SBJson.h"
#import "KCSRESTRequest.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCSConnectionResponse.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "KCSObjectMapper.h"
#import "KCSQuery.h"


// Avoid compiler warning by prototyping here...
KCSConnectionCompletionBlock makeCollectionCompletionBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate);
KCSConnectionFailureBlock    makeCollectionFailureBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate);
KCSConnectionProgressBlock   makeCollectionProgressBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate);

KCSConnectionCompletionBlock makeCollectionCompletionBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate)
{
    return [[^(KCSConnectionResponse *response){
        
        KCSLogTrace(@"In collection callback with response: %@", response);
        NSMutableArray *processedData = [[NSMutableArray alloc] init];
        
        
        // New KCS behavior, not ready yet
#if 0
        NSDictionary *jsonResponse = [response.responseData objectFromJSONData];
        NSObject *jsonData = [jsonResponse valueForKey:@"result"];
#else  
        KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
        NSObject *jsonData = [parser objectWithData:response.responseData];
        [parser release];
#endif        
        NSArray *jsonArray;
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Collection fetch was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", jsonData]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate collection:collection didFailWithError:error];

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
        [delegate collection:collection didCompleteWithResult:processedData];
        [processedData release];
    } copy] autorelease];
}

KCSConnectionFailureBlock    makeCollectionFailureBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate)
{
    return [[^(NSError *error){
        [delegate collection:collection didFailWithError:error];
    } copy] autorelease];
}
KCSConnectionProgressBlock   makeCollectionProgressBlock(KCSCollection *collection, id<KCSCollectionDelegate>delegate)
{
    
    return [[^(KCSConnectionProgress *conn)
    {
        // Do nothing...
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
        _collectionName = [name retain];
        _objectTemplate = theClass;
        _lastFetchResults = nil;
        _baseURL = [[[KCSClient sharedClient] appdataBaseURL] retain]; // Initialize this to the default appdata URL
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
    
    if (![self.filters isEqualToArray:c.filters]){
        return NO;
    }
    
    return YES;
}



+ (KCSCollection *)collectionFromString: (NSString *)string ofClass: (Class)templateClass
{
    KCSCollection *collection = [[[KCSCollection alloc] initWithName:string forTemplateClass:templateClass] autorelease];
    return collection;
}



#pragma mark Basic Methods

- (void)fetchAllWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    NSString *resource = [self.baseURL stringByAppendingFormat:@"%@/", self.collectionName];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    KCSConnectionCompletionBlock cBlock = makeCollectionCompletionBlock(self, delegate);
    KCSConnectionFailureBlock fBlock = makeCollectionFailureBlock(self, delegate);
    KCSConnectionProgressBlock pBlock = makeCollectionProgressBlock(self, delegate);
    
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

- (void)fetchWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    // Guard against an empty filter
    if (self.filters.count == 0 && self.query == nil){
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

        // NB: All of the modifiers are optional and may be combined in any order.  However, we ended up here
        //     so the user made an attempt to set some...
        
        // Add the Query portion of the request
        if (self.query.query != nil && self.query.query.count > 0){
            resource = [resource stringByAppendingQueryString:[self.query parameterStringRepresentation]];
        }
        
        // Add any sort modifiers
        if (self.query.sortModifiers.count > 0){
            resource = [resource stringByAppendingQueryString:[self.query parameterStringForSortKeys]];
        }
        
        // Add any limit modifiers
        if (self.query.limitModifer != nil){
            resource = [resource stringByAppendingQueryString:[self.query.limitModifer parameterStringRepresentation]];
        }
        
        // Add any skip modifiers
        if (self.query.skipModifier != nil){
            resource = [resource stringByAppendingQueryString:[self.query.skipModifier parameterStringRepresentation]];
        }
        
    } else {
        resource = [self.baseURL stringByAppendingFormat:format, self.collectionName];
        resource = [resource stringByAppendingQueryString:[NSString stringWithFormat:@"query=%@", [NSString stringByPercentEncodingString:[self buildQueryForFilters:[self filters]]]]];
    }

    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    
    KCSConnectionCompletionBlock cBlock = makeCollectionCompletionBlock(self, delegate);
    KCSConnectionFailureBlock fBlock = makeCollectionFailureBlock(self, delegate);
    KCSConnectionProgressBlock pBlock = makeCollectionProgressBlock(self, delegate);
    
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
        KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
        NSDictionary *jsonResponse = [parser objectWithData:response.responseData];
        [parser release];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        int count;

        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Information request was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", responseToReturn]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate collection:self informationOperationFailedWithError:error];
            return;
        }

        NSString *val = [responseToReturn valueForKey:@"count"];
        
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

// AVG is not in the REST docs anymore


@end
