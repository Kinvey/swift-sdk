//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyEntity.h"

#import "KCSClient.h"
#import "KCSRESTRequest.h"
#import "KinveyCollection.h"
#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"
#import "KinveyBlocks.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "SBJson.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSObjectMapper.h"
#import "KCSLogManager.h"

//#import "KinveyCollection.h"
//

//#import "KinveyPersistable.h"

// For assoc storage
#import <Foundation/Foundation.h>


// Avoid compiler warning by prototyping here...
void
makeConnectionBlocks(KCSConnectionCompletionBlock *cBlock,
                     KCSConnectionFailureBlock *fBlock,
                     KCSConnectionProgressBlock *pBlock,
                     id objectOfInterest,
                     id <KCSEntityDelegate> delegate);

void
makeConnectionBlocks(KCSConnectionCompletionBlock *cBlock,
                     KCSConnectionFailureBlock *fBlock,
                     KCSConnectionProgressBlock *pBlock,
                     id objectOfInterest,
                     id <KCSEntityDelegate> delegate)
{
     *cBlock = [^(KCSConnectionResponse *response){
         KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonResponse = [parser objectWithData:response.responseData];
#if 0
        // Needs KCS update for this feature
//        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
//        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Entity fetch operation was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", (NSDictionary *)jsonResponse]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate entity:objectOfInterest fetchDidFailWithError:error];

        } else {
            // Populate our object and return it to the delegate
            NSDictionary *responseToReturn = nil;
            
            if ([jsonResponse isKindOfClass:[NSArray class]]){
                responseToReturn = (NSDictionary *)[(NSArray *)jsonResponse objectAtIndex:0];
            } else {
                responseToReturn = (NSDictionary *)jsonResponse;
            }
            [delegate entity:[KCSObjectMapper populateObject:objectOfInterest withData:responseToReturn] fetchDidCompleteWithResult:responseToReturn];
        }
    } copy];
    
    *fBlock = [^(NSError *error){
        [delegate entity:objectOfInterest fetchDidFailWithError:error];
    } copy];
    
    *pBlock = [^(KCSConnectionProgress *conn)
    {
        // Do nothing...
    } copy];
   
}


@implementation NSObject (KCSEntity)


- (void)fetchOneFromCollection:(KCSCollection *)collection matchingQuery:(NSString *)query withDelegate:(id<KCSEntityDelegate>)delegate
{
    NSString *resource = nil;
    // This is the user collection...
    if ([collection.collectionName isEqualToString:@""]){
        resource = [collection.baseURL stringByAppendingFormat:@"%@",
                    [NSString stringbyPercentEncodingString:query]];

    } else {
        resource = [collection.baseURL stringByAppendingFormat:@"%@/%@",
                    [collection collectionName],
                    [NSString stringbyPercentEncodingString:query]];

    }


    KCSConnectionCompletionBlock cBlock;
    KCSConnectionFailureBlock fBlock;
    KCSConnectionProgressBlock pBlock;
    
    makeConnectionBlocks(&cBlock, &fBlock, &pBlock, self, delegate);
    [[[KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod] withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (void)findEntityWithProperty:(NSString *)property matchingBoolValue:(BOOL)value fromCollection:(KCSCollection *)collection withDelegate:(id<KCSEntityDelegate>)delegate
{
    
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:value], property, nil] JSONRepresentation];
    
    [self fetchOneFromCollection:collection matchingQuery:[NSString stringbyPercentEncodingString:query] withDelegate:delegate];
    
}

- (void)findEntityWithProperty:(NSString *)property matchingDoubleValue:(double)value fromCollection:(KCSCollection *)collection withDelegate:(id<KCSEntityDelegate>)delegate
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:value], property, nil] JSONRepresentation];
    
    [self fetchOneFromCollection:collection matchingQuery:[NSString stringbyPercentEncodingString:query] withDelegate:delegate];
    
}

- (void)findEntityWithProperty:(NSString *)property matchingIntegerValue:(int)value fromCollection:(KCSCollection *)collection withDelegate:(id<KCSEntityDelegate>)delegate
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:value], property, nil] JSONRepresentation];
    
    [self fetchOneFromCollection:collection matchingQuery:[NSString stringbyPercentEncodingString:query] withDelegate:delegate];
    
}

- (void)findEntityWithProperty:(NSString *)property matchingStringValue:(NSString *)value fromCollection:(KCSCollection *)collection withDelegate:(id<KCSEntityDelegate>)delegate
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:value, property, nil] JSONRepresentation];
    
    [self fetchOneFromCollection:collection matchingQuery:[NSString stringbyPercentEncodingString:query] withDelegate:delegate];
    
}

- (NSString *)kinveyObjectId
{
    NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName isEqualToString:@"_id"]){
            return [self valueForKey:key];
        }
    }
    return nil;
}


- (NSString *)valueForProperty: (NSString *)property
{
    if ([property isEqualToString:@"_id"]){
        return [self kinveyObjectId];
    } else {
        NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
        for (NSString *key in kinveyMapping){
            NSString *jsonName = [kinveyMapping valueForKey:key];
            if ([property isEqualToString:jsonName]){
                return [self valueForKey:key];
            }
        }
        // Didn't find anything yet, search the dictionary if there is one
        if ([[[[self class] kinveyObjectBuilderOptions] objectForKey:KCS_USE_DICTIONARY_KEY] boolValue]){
            // Need to check dictionary
            NSString *dictionaryName = [[[self class] kinveyObjectBuilderOptions] objectForKey:KCS_DICTIONARY_NAME_KEY];
            NSString *keyPath = [dictionaryName stringByAppendingFormat:@".%@", property];
            return [self valueForKeyPath:keyPath];
        }
    }
    // Nothing found, return nil
    return nil;
}

- (void)loadObjectWithID:(NSString *)objectID fromCollection:(KCSCollection *)collection withDelegate:(id<KCSEntityDelegate>)delegate
{
    NSString *resource = nil;
    // This is the user collection...
    if ([collection.collectionName isEqualToString:@""]){
        resource = [collection.baseURL stringByAppendingFormat:@"%@", objectID];
    } else {
        resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, objectID];
    }

    KCSConnectionCompletionBlock cBlock;
    KCSConnectionFailureBlock fBlock;
    KCSConnectionProgressBlock pBlock;
    
    makeConnectionBlocks(&cBlock, &fBlock, &pBlock, self, delegate);
    [[[KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod] withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (void)setValue: (NSString *)value forProperty: (NSString *)property
{
    [self setValue:value forKey:property];
}

- (void)saveToCollection:(KCSCollection *)collection withDelegate:(id<KCSPersistableDelegate>)delegate
{

    KCSSerializedObject *obj = [KCSObjectMapper makeKinveyDictionaryFromObject:self];
    BOOL isPostRequest = obj.isPostRequest;
    NSString *objectId = obj.objectId;
    NSDictionary *dictionaryToMap = [obj.dataToSerialize retain];
    
    NSString *resource = nil;
    if ([collection.collectionName isEqualToString:@""]){
        resource = [collection.baseURL stringByAppendingFormat:@"%@", objectId];        
    } else {
        resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];
    }
    

    NSInteger HTTPMethod;
    
    // If we need to post this, then do so
    if (isPostRequest){
        HTTPMethod = kPostRESTMethod;
    } else {
        HTTPMethod = kPutRESTMethod;
    }

    
    // Prepare our request
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:HTTPMethod];

    // This is a JSON request
    [request setContentType:KCS_JSON_TYPE];
    
    // Make sure to include the UTF-8 encoded JSONData...
    KCS_SBJsonWriter *writer = [[[KCS_SBJsonWriter alloc] init] autorelease];
    [request addBody:[writer dataWithObject:dictionaryToMap]];
    
    // Prepare our handlers
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonResponse = [parser objectWithData:response.responseData];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_CREATED && response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Entity operation was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", responseToReturn]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate entity:self operationDidFailWithError:error];

        } else {
            [delegate entity:self operationDidCompleteWithResult:responseToReturn];
        }
    };

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate entity:self operationDidFailWithError:error];
    };
    
    // Future enhancement
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];

    [dictionaryToMap release];

}

- (void)deleteFromCollection:(KCSCollection *)collection withDelegate:(id<KCSPersistableDelegate>)delegate
{
    NSString *oid = [self kinveyObjectId];
    NSString *resource = nil;
    if ([collection.collectionName isEqualToString:@""]){
        resource = [collection.baseURL stringByAppendingFormat:@"%@", oid];
    } else {
        resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, oid];
    }
    
    // Prepare our request
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kDeleteRESTMethod];
    
    // Prepare our handlers
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonResponse = [parser objectWithData:response.responseData];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_NO_CONTENT){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Entity operation was unsuccessful."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", responseToReturn]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSAppDataErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate entity:self operationDidFailWithError:error];
        } else {
            [delegate entity:self operationDidCompleteWithResult:responseToReturn];
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate entity:self operationDidFailWithError:error];
    };
    
    // Future enhancement
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"UnsupportedFeatureException", @"This version of the Kinvey iOS library requires clients to override this method");
    
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This version of the Kinvey iOS library requires clients to override this method"
                                userInfo:nil];
    
    @throw myException;

    return nil;
}

+ (id)kinveyDesignatedInitializer
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"UnsupportedFeatureException", @"This version of the Kinvey iOS library requires clients to override this method");
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This version of the Kinvey iOS library requires clients to override this method"
                                userInfo:nil];
    
    @throw myException;
    
    return nil;

}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return nil;
}


@end
