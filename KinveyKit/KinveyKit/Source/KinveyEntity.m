//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyEntity.h"

#import "KCSClient.h"
#import "KCSConnection.h"
#import "KCSRESTRequest.h"
#import "KinveyCollection.h"
#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"
#import "KinveyBlocks.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "JSONKit.h"

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
     *cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonResponse = [response.responseData objectFromJSONData];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:responseToReturn];
            [delegate fetchDidFail:err];
        } else {
            NSDictionary *kinveyMapping = [objectOfInterest hostToKinveyPropertyMapping];
            
            NSString *key;
            for (key in kinveyMapping){
                [objectOfInterest setValue:[responseToReturn valueForKey:[kinveyMapping valueForKey:key]] forKey:key];
            }
            [delegate fetchDidComplete:responseToReturn];
        }
    };
    
    *fBlock = ^(NSError *error){
        [delegate fetchDidFail:error];  
    };
    
    *pBlock = ^(KCSConnection *conn)
    {
        // Do nothing...
    };
   
}

// Declare several static vars here to create unique pointers to serve as keys
// for the assoc objects
@implementation NSObject (KCSEntity)


- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query fromCollection: (KCSCollection *)collection;
{
    KCSClient *kinveyClient = [KCSClient sharedClient];

    NSString *resource = [kinveyClient.dataBaseURL stringByAppendingFormat:@"%@/%@",
                          [collection collectionName],
                          [NSString stringbyPercentEncodingString:query]];

    KCSConnectionCompletionBlock cBlock;
    KCSConnectionFailureBlock fBlock;
    KCSConnectionProgressBlock pBlock;
    
    makeConnectionBlocks(&cBlock, &fBlock, &pBlock, self, delegate);
    [[[KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod] withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value fromCollection: (KCSCollection *)collection;
{
    
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:[NSString stringbyPercentEncodingString:query] fromCollection:collection];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value fromCollection: (KCSCollection *)collection;
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"JSON Data Support not yet implemented"
                                userInfo:nil];
    @throw myException;

    //    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:value], property, nil] JSONString];
    
//    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value fromCollection: (KCSCollection *)collection;
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:[NSString stringbyPercentEncodingString:query] fromCollection:collection];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value fromCollection: (KCSCollection *)collection;
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:[NSString stringbyPercentEncodingString:query] fromCollection:collection];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value fromCollection: (KCSCollection *)collection;
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:value, property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:[NSString stringbyPercentEncodingString:query] fromCollection:collection];
    
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
    }
    // Nothing found, return nil
    return nil;
}

- (void)entityDelegate:(id <KCSEntityDelegate>)delegate loadObjectWithId:(NSString *)objectId fromCollection:(KCSCollection *)collection
{
    NSString *resource = [[[KCSClient sharedClient] dataBaseURL] stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];

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

- (void)persistDelegate:(id <KCSPersistDelegate>)delegate persistToCollection:(KCSCollection *)collection
{
    BOOL isPostRequest = NO;

    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
    NSString *objectId = nil;

    NSString *key;
    for (key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        [dictionaryToMap setValue:[self valueForKey:key] forKey:jsonName];
        
        if ([jsonName isEqualToString:@"_id"]){
            objectId = [self valueForKey:key];
            if (objectId == nil){
                isPostRequest = YES;
                objectId = @""; // Set to the empty string for the document path
            } else {
                isPostRequest = NO;
            }
        }
    }

    
    NSString *resource = [[[KCSClient sharedClient] dataBaseURL] stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];
    

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
    [request addBody:[dictionaryToMap JSONData]];
    
    // Prepare our handlers
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonResponse = [response.responseData objectFromJSONData];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_CREATED && response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:responseToReturn];
            [delegate persistDidFail:err];
        } else {
            [delegate persistDidComplete:responseToReturn];
        }
    };

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate persistDidFail:error];
    };
    
    // Future enhancement
    KCSConnectionProgressBlock pBlock = ^(KCSConnection *conn){};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];

    [dictionaryToMap release];

}

- (void)deleteDelegate:(id<KCSPersistDelegate>)delegate fromCollection:(KCSCollection *)collection
{
    NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
    
    NSString *oid = nil;
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName compare:@"_id"] == NSOrderedSame){
            oid = [self valueForKey:key];
        }
    }

    NSString *resource = [[[KCSClient sharedClient] dataBaseURL] stringByAppendingFormat:@"%@/%@", collection.collectionName, oid];
    
    // Prepare our request
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kDeleteRESTMethod];
    
    // Prepare our handlers
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonResponse = [response.responseData objectFromJSONData];
#if 0
        // Needs KCS update for this feature
        NSDictionary *responseToReturn = [jsonResponse valueForKey:@"result"];
#else
        NSDictionary *responseToReturn = jsonResponse;
#endif
        
        if (response.responseCode != KCS_HTTP_STATUS_NO_CONTENT){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:responseToReturn];
            [delegate persistDidFail:err];
        } else {
            [delegate persistDidComplete:responseToReturn];
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate persistDidFail:error];
    };
    
    // Future enhancement
    KCSConnectionProgressBlock pBlock = ^(KCSConnection *conn){};
    
    // Make the request happen
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This version of the Kinvey iOS library requires clients to override this method"
                                userInfo:nil];
    
    @throw myException;

    return nil;
}


@end
