//
//  KCSAppdataStore.h
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSStore.h"

@class KCSCollection;

/**
 KCSStore options dictionary key for the backing resource
 */
#define KCSStoreKeyResource @"resource"

/**
 Basic Store for loading Application Data from a Collection in the Kinvey backend. 
 
 The preferred use of this class is to use a KCSCachedStore with a `cachePolicy` of `KCSCachePolicyNone`.
 
 @see KCSCachedStore
 */
@interface KCSAppdataStore : NSObject <KCSStore>

@property (nonatomic, retain) KCSAuthHandler *authHandler;


/** Initialize an empty store with the given collections, options and the default authentication
 
 This will initialize an empty store with the given options and default authentication,
 the given options dictionary should be defined by the Kinvey Store that implements
 the protocol.
 
 @param collection the Kinvey backend Collection providing data to this store.
 @param options A dictionary of options to configure the store. (Can be nil if there are no options)
 @see [KCSStore storeWithOptions:]
 @return An autoreleased empty store with configured options and default authentication. 
 */
+ (id) storeWithCollection:(KCSCollection*)collection options:(NSDictionary*)options;

/** Initialize an empty store with the given options and the given authentication
 
 This will initialize an empty store with the given options and given authentication,
 the options dictionary should be defined by the Kinvey Store that implements
 the protocol.  Authentication is Kinvey Store specific, refer to specific store's
 documentation for details.
 
 @param collection the Kinvey backend Collection providing data to this store.
 @param options A dictionary of options to configure the store. (Can be nil if there are no options)
 @param authHandler The Kinvey Authentication Handler used to authenticate backend requests.
 
 @see [KCSStore storeWithAuthHandler:withOptions:]
 @return An autoreleased empty store with configured options and given authentication.
 */
+ (id)storeWithCollection:(KCSCollection*)collection authHandler:(KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options;

@end
