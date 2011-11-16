//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyEntity.h"
#import "KCSClient.h"
#import "KinveyCollection.h"

#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"
#import "JSONKit.h"
#import "KinveyPersistable.h"

// For assoc storage
#import <Foundation/Foundation.h>


// Declare several static vars here to create unique pointers to serve as keys
// for the assoc objects
@implementation NSObject (KCSEntity)



- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query fromCollection: (KCSCollection *)collection;
{

    NSString *baseQuery = [[[collection kinveyClient] baseURL] stringByAppendingFormat:@"%@/", [collection collectionName]];
    NSString *builtQuery = [baseQuery URLStringByAppendingQueryString:[NSString stringbyPercentEncodingString:query]];
                           
    KCSEntityDelegateMapper *mapper = [[KCSEntityDelegateMapper alloc] init];
    [mapper setMappedDelegate:delegate];
    [mapper setObjectToLoad:self];
    
    [[collection kinveyClient] clientActionDelegate:mapper forGetRequestAtPath:builtQuery];
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value usingClient: (KCSClient *)client
{
    
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value usingClient: (KCSClient *)client
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"JSON Data Support not yet implemented"
                                userInfo:nil];
    @throw myException;

    //    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:value], property, nil] JSONString];
    
//    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value usingClient: (KCSClient *)client
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value usingClient: (KCSClient *)client
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:value], property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value usingClient: (KCSClient *)client 
{
    NSString *query = [[NSDictionary dictionaryWithObjectsAndKeys:value, property, nil] JSONString];
    
    [self entityDelegate:delegate shouldFetchOne:query usingClient:client];
    
}



- (NSString *)valueForProperty: (NSString *)property
{
    if ([property isEqualToString:@"_id"]){
        // String is _id, so this is our special case
        return [self objectId];
    } else {
        return [self valueForKey:property];
    }
    return nil;
}

- (void)entityDelegate:(id <KCSEntityDelegate>)delegate loadObjectWithId:(NSString *)objectId fromCollection:(KCSCollection *)collection
{
    KCSEntityDelegateMapper *deferredLoader = [[KCSEntityDelegateMapper alloc] init];
    [deferredLoader setMappedDelegate:delegate];
    [deferredLoader setObjectToLoad:self];

    NSString *idLocation = [[[collection kinveyClient] baseURL] stringByAppendingFormat:@"%@/%@", [self entityColleciton], objectId];
    [[collection kinveyClient ] clientActionDelegate:deferredLoader forGetRequestAtPath:idLocation];
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
    NSString *objectId;

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

    KCSPersistDelegateMapper *mapping = [[KCSPersistDelegateMapper alloc] init];

    [mapping setMappedDelegate:delegate];
    NSString *documentPath = [[[collection kinveyClient] baseURL] stringByAppendingFormat:@"%@/%@", [collection collectionName], objectId];
    
    
    // If we need to post this, then do so
    if (isPostRequest){
        [[collection kinveyClient] clientActionDelegate:mapping forPostRequest:[dictionaryToMap JSONData] atPath:documentPath];
    } else {
        // Otherwise we just put the data on Kinvey
        [[collection kinveyClient] clientActionDelegate:mapping forPutRequest:[dictionaryToMap JSONData] atPath:documentPath];
    }

    [dictionaryToMap release];

}

- (void)deleteDelegate:(id<KCSPersistDelegate>)delegate fromCollection:(KCSCollection *)collection
{
    KCSPersistDelegateMapper *mapping = [[KCSPersistDelegateMapper alloc] init];
    
    [mapping setMappedDelegate:delegate];
    NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
    
    NSString *oid = nil;
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName compare:@"_id"] == NSOrderedSame){
            oid = [self valueForKey:key];
        }
    }

    NSString *documentPath = [[[collection kinveyClient] baseURL] stringByAppendingFormat:@"%@/%@", [collection collectionName], oid];
    
    [[collection kinveyClient] clientActionDelegate:mapping forDeleteRequestAtPath:documentPath];
    

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


@implementation KCSEntityDelegateMapper

@synthesize mappedDelegate;
@synthesize objectToLoad;
@synthesize jsonDecoder;
@synthesize kinveyClient=_kinveyClient;


- (id)init {
    self = [super init];
    
    if (self){
        jsonDecoder = [[JSONDecoder alloc] init];
        [self setKinveyClient:nil];
    }
    return self;

}

- (void)dealloc
{
    // Do something
    [jsonDecoder release];
    [mappedDelegate release];
    [objectToLoad release];
    [super dealloc];
}


- (void) actionDidFail: (id)error
{
    NSLog(@"Load failed!");
    // Load failed, leave the object alone, nothing is needed here.
    [mappedDelegate fetchDidFail:error];
}

- (void) actionDidComplete: (NSObject *) result
{
    NSLog(@"KCSEntityDelegateMapper loading request and delegating to %@", mappedDelegate);
    if (objectToLoad == Nil){
        NSException* myException = [NSException
                                    exceptionWithName:@"NilPointerException"
                                    reason:@"EntityDelegateMapper attempting to retrieve entity into Nil object."
                                    userInfo:nil];
        @throw myException;
    }

    NSDictionary *jsonData = [jsonDecoder objectWithData:(NSData *)result];
    NSDictionary *kinveyMapping = [objectToLoad hostToKinveyPropertyMapping];

    NSString *key;
    for (key in kinveyMapping){
        [objectToLoad setValue:[jsonData valueForKey:[kinveyMapping valueForKey:key]] forKey:key];
    }

    [mappedDelegate fetchDidComplete:result];
}


@end

@implementation KCSPersistDelegateMapper

@synthesize mappedDelegate;

- (void) actionDidFail: (id)error
{
    NSLog(@"Persist failed!");
    // Load failed, leave the object alone, nothing is needed here.
    [mappedDelegate persistDidFail:error];
}

- (void) actionDidComplete: (NSObject *) result
{
    NSLog(@"TRACE: actionDidComplete: %@ (to: %@)", [(NSData*) result objectFromJSONData], mappedDelegate);
    [mappedDelegate persistDidComplete:result];
}

- (void)dealloc {
    [mappedDelegate release];
    [super dealloc];
}


@end
