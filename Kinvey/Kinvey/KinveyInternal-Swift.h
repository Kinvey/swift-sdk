//
//  KinveyInternal-Swift.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Kinvey/Kinvey-Swift.h>

@class __KNVCacheManager;

@interface NSString ()

-(NSDate* _Nullable)toDate;

@end

@interface KNVRealmEntitySchema : NSObject

+(NSString* _Nullable)realmClassNameForClass:(Class _Nonnull)cls;

@end

@protocol KNVPendingOperation

@property (nonatomic, readonly, copy) NSString * _Nullable objectId;

- (NSURLRequest * _Nonnull)buildRequest;

@end

@protocol __KNVSync

@property (nonatomic, copy) NSString * _Nonnull persistenceId;
@property (nonatomic, copy) NSString * _Nonnull collectionName;

- (null_unspecified instancetype)initWithPersistenceId:(NSString * _Nonnull)persistenceId
                                        collectionName:(NSString * _Nonnull)collectionName;

- (id <KNVPendingOperation> _Nonnull)createPendingOperation:(NSURLRequest * _Null_unspecified)request
                                                   objectId:(NSString * _Nullable)objectId;

- (void)savePendingOperation:(id <KNVPendingOperation> _Nonnull)pendingOperation;
- (NSArray<id <KNVPendingOperation>> * _Nonnull)pendingOperations;
- (NSArray<id <KNVPendingOperation>> * _Nonnull)pendingOperations:(NSString * _Nullable)objectId;
- (void)removePendingOperation:(id <KNVPendingOperation> _Nonnull)pendingOperation;
- (void)removeAllPendingOperations;
- (void)removeAllPendingOperations:(NSString * _Nullable)objectId;

@end

@protocol __KNVCache

@property (nonatomic, copy) NSString * _Nonnull persistenceId;
@property (nonatomic, copy) NSString * _Nonnull collectionName;
@property (nonatomic) NSTimeInterval ttl;

- (void)saveEntity:(NSDictionary<NSString *, id> * _Nonnull)entity;
- (void)saveEntities:(NSArray<NSDictionary<NSString *, id> *> * _Nonnull)entities;
- (NSDictionary<NSString *, id> * _Nullable)findEntity:(NSString * _Nonnull)objectId;
- (NSArray<NSDictionary<NSString *, id> *> * _Nonnull)findEntityByQuery:(KNVQuery * _Nonnull)query;
- (NSDictionary<NSString *, NSString *> * _Nonnull)findIdsLmtsByQuery:(KNVQuery * _Nonnull)query;
- (NSArray<NSDictionary<NSString *, id> *> * _Nonnull)findAll;
- (NSUInteger)count;
- (BOOL)removeEntity:(NSDictionary<NSString *, id> * _Nonnull)entity;
- (NSUInteger)removeEntitiesByQuery:(KNVQuery * _Nonnull)query;
- (void)removeAllEntities;

@end

@interface __KNVSyncManager : NSObject

- (id <__KNVSync> _Nonnull)sync:(NSString * _Nonnull)collectionName;

@end

@interface __KNVCacheManager : NSObject

- (id <__KNVCache> _Nonnull)cache:(NSString * _Nullable)collectionName;

@end

@interface __KNVClient (Kinvey)

@property (nonatomic, readonly, strong) __KNVCacheManager * _Null_unspecified cacheManager;
@property (nonatomic, readonly, strong) __KNVSyncManager * _Null_unspecified syncManager;

@end

@interface __KNVOperation : NSObject
@end

@interface __KNVReadOperation : __KNVOperation

- (id <KNVRequest> _Nonnull)execute:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;

@end

@interface __KNVWriteOperation : __KNVOperation

- (id <KNVRequest> _Nonnull)execute:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;

@end

@interface __KNVSyncOperation : __KNVOperation

- (nonnull instancetype)initWithSync:(id <__KNVSync> _Nonnull)sync
                     persistableType:(Class <KNVPersistable> _Nonnull)persistableType
                               cache:(id <__KNVCache> _Nonnull)cache
                              client:(__KNVClient * _Nonnull)client OBJC_DESIGNATED_INITIALIZER;

- (id <KNVRequest> _Nonnull)execute:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;
- (id <KNVRequest> _Nonnull)executeUInt:(void (^ _Nullable)(NSUInteger, NSError * _Nullable))completionHandler;

@end

@interface __KNVSaveOperation : __KNVWriteOperation

- (nonnull instancetype)initWithPersistable:(id <KNVPersistable> _Nonnull)persistable
                                writePolicy:(enum WritePolicy)writePolicy
                                       sync:(id <__KNVSync> _Nonnull)sync
                                      cache:(id <__KNVCache> _Nonnull)cache
                                     client:(__KNVClient * _Nonnull)client OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVGetOperation : __KNVReadOperation

- (nonnull instancetype)initWithId:(NSString * _Nonnull)objectId
                        readPolicy:(enum ReadPolicy)readPolicy
                   persistableType:(Class <KNVPersistable> _Nonnull)persistableClass
                             cache:(id <__KNVCache> _Nonnull)cache
                            client:(__KNVClient * _Nonnull)client;

@end

@interface __KNVFindOperation : __KNVReadOperation

- (nonnull instancetype)initWithQuery:(KNVQuery * _Nonnull)query
                             deltaSet:(BOOL)deltaSet
                           readPolicy:(enum ReadPolicy)readPolicy
                      persistableType:(Class <KNVPersistable> _Nonnull)persistableClass
                                cache:(id <__KNVCache> _Nonnull)cache
                               client:(__KNVClient * _Nonnull)client;

@end

@interface __KNVRemoveOperation : __KNVWriteOperation

- (nonnull instancetype)initWithQuery:(KNVQuery * _Nonnull)query
                          writePolicy:(enum WritePolicy)writePolicy
                                 sync:(id <__KNVSync> _Nonnull)sync
                      persistableType:(Class <KNVPersistable> _Nonnull)persistableType
                                cache:(id <__KNVCache> _Nonnull)cache
                               client:(__KNVClient * _Nonnull)client OBJC_DESIGNATED_INITIALIZER;

- (id <KNVRequest> _Nonnull)executeUInt:(void (^ _Nullable)(NSUInteger, NSError * _Nullable))completionHandler;

@end

@interface __KNVPushOperation : __KNVSyncOperation

- (nonnull instancetype)initWithSync:(id <__KNVSync> _Nonnull)sync
                     persistableType:(Class <KNVPersistable> _Nonnull)persistableType
                               cache:(id <__KNVCache> _Nonnull)cache
                              client:(__KNVClient * _Nonnull)client OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVPurgeOperation : __KNVSyncOperation

- (nonnull instancetype)initWithSync:(id <__KNVSync> _Nonnull)sync
                     persistableType:(Class <KNVPersistable> _Nonnull)persistableType
                               cache:(id <__KNVCache> _Nonnull)cache
                              client:(__KNVClient * _Nonnull)client OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVPersistable : NSObject

+ (NSString * _Nonnull)idKey:(Class <KNVPersistable> _Nonnull)type;
+ (NSString * _Nullable)kmdKey:(Class <KNVPersistable> _Nonnull)type;
+ (NSString * _Nullable)kinveyObjectId:(id <KNVPersistable> _Nonnull)persistable;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVQuery : NSObject

+ (KNVQuery * _Nonnull)query:(KNVQuery * _Nonnull)query
             persistableType:(Class <KNVPersistable> _Nonnull)persistableType;

- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVError : NSObject

+ (NSError * _Nonnull)ObjectIdMissing;
+ (NSError * _Nonnull)InvalidResponse;
+ (NSError * _Nonnull)NoActiveUser;
+ (NSError * _Nonnull)RequestCanceled;
+ (NSError * _Nonnull)InvalidStoreType;

@end

@interface __KNVLocalRequest : NSObject <KNVRequest>

@property (nonatomic, readonly) BOOL executing;
@property (nonatomic, readonly) BOOL canceled;

- (void)cancel;

@end

@interface __KNVMultiRequest : NSObject <KNVRequest>

@property (nonatomic, readonly) BOOL executing;
@property (nonatomic, readonly) BOOL canceled;

- (void)addRequest:(id <KNVRequest> _Nonnull)request;
- (void)cancel;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVObjCRuntime : NSObject

+ (NSArray<NSString *> * _Nullable)propertyNamesForTypeInClass:(Class _Nonnull)cls type:(Class _Nonnull)type;
+ (Class _Nullable)typeForPropertyName:(Class _Nonnull)cls propertyName:(NSString * _Nonnull)propertyName;

@end
