//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyEntity.h"
#import "KCSClient.h"

#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"

#import "JSONKit.h"
#import "KinveyPersistable.h"

// For assoc storage
#import <objc/runtime.h>
#import <Foundation/Foundation.h>


// Declare several static vars here to create unique pointers to serve as keys
// for the assoc objects
static char collectionKey;
static char oidKey;

@implementation NSObject (KCSEntity)



- (void)setEntityCollection: (NSString *)entityCollection
{
    objc_setAssociatedObject(self,
                             &collectionKey,
                             entityCollection,
                             OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)entityColleciton
{
    return objc_getAssociatedObject(self, &collectionKey);
}

- (NSString *)objectId{
    return objc_getAssociatedObject(self, &oidKey);
}

- (void)setObjectId: (NSString *)objectId{
    objc_setAssociatedObject(self, &oidKey, objectId, OBJC_ASSOCIATION_RETAIN);
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query usingClient: (KCSClient *)client
{

    NSString *builtQuery = [[[client baseURI] stringByAppendingPathComponent:[self entityColleciton]] URLStringByAppendingQueryString:query];
    
    KCSEntityDelegateMapper *mapper = [[KCSEntityDelegateMapper alloc] init];
    [mapper setMappedDelegate:delegate];
    [mapper setObjectToLoad:self];
    [client clientActionDelegate:mapper forGetRequestAtPath:builtQuery];
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
    if ([property compare:@"_id"] == NSOrderedSame){
        // String is _id, so this is our special case
        return [self objectId];
    } else {
        return [self valueForKey:property];
    }
    return nil;
}

- (void)entityDelegate:(id <KCSEntityDelegate>)delegate loadObjectWithId:(NSString *)objectId usingClient:(KCSClient *)client
{
    KCSEntityDelegateMapper *deferredLoader = [[KCSEntityDelegateMapper alloc] init];
    [deferredLoader setMappedDelegate:delegate];
    [deferredLoader setObjectToLoad:self];

    NSString *idLocation = [[client baseURI] stringsByAppendingPaths:[NSArray arrayWithObjects:[self entityColleciton], objectId, nil]];
    [client clientActionDelegate:deferredLoader forGetRequestAtPath:idLocation];
}

- (void)setValue: (NSString *)value forProperty: (NSString *)property
{
    if ([property compare:@"_id"] == NSOrderedSame){
        [self setObjectId:value];
    } else {
        [self setValue:value forKey:property];
    }
}

- (void)persistDelegate:(id <KCSPersistDelegate>)delegate persistUsingClient:(KCSClient *)client {

    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [self propertyToElementMapping];

    NSString *key;
    for (key in kinveyMapping){
        [dictionaryToMap setValue:[self valueForKey:key] forKey:key];
    }

    KCSPersistDelegateMapper *mapping = [[KCSPersistDelegateMapper alloc] init];

    [mapping setMappedDelegate:delegate];
    NSString *documentPath = [[client baseURI] stringByAppendingPathExtension:[self entityColleciton]];
    [client clientActionDelegate:mapping forPostRequest:[dictionaryToMap JSONData] atPath:documentPath];

    [dictionaryToMap release];
    [mapping release];

}

- (NSDictionary *)propertyToElementMapping
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This version of the Kinvey iOS library requires clients to override this method"
                                userInfo:nil];

    return nil;
}


@end


@implementation KCSEntityDelegateMapper

@synthesize mappedDelegate;
@synthesize objectToLoad;
@synthesize jsonDecoder;


- (id)init {
    self = [super init];
    
    if (self){
        jsonDecoder = [[JSONDecoder alloc] init];
    }

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
    NSDictionary *kinveyMapping = [objectToLoad propertyToElementMapping];

    NSString *key;
    for (key in kinveyMapping){
        [objectToLoad setValue:[kinveyMapping valueForKey:key] forKey:key];
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
    [mappedDelegate persistDidComplete:result];
}

- (void)dealloc {
    [mappedDelegate release];
    [super dealloc];
}


@end
