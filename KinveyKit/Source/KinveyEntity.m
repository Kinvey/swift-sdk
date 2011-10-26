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

// For assoc storage
#import <objc/runtime.h>

// Declare several static vars here to create uniuqe pointers to serve as keys
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
    return nil;
}

- (void)delagate: (id)delagate loadObjectWithId: (NSString *)objectId
{
    
}

- (void)setValue: (NSString *)value forProperty: (NSString *)property
{
    
}


@end


@implementation KCSEntityDelegateMapper

@synthesize mappedDelegate;

- (void) actionDidFail: (id)error
{
    [mappedDelegate fetchDidFail:error];
}

- (void) actionDidComplete: (NSObject *) result
{

    [mappedDelegate fetchDidComplete:result];
}


@end

