//
//  KCSEntityCache2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/14/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSEntityCache2.h"
#import "KCSEntityCache.h"

#import "KinveyEntity.h"
#import "KCSObjectMapper.h"
#import "KCSReduceFunction.h"
#import "KCSHiddenMethods.h"
#import "KCSGroup.h"

#import "KCSLogManager.h"
#import "KCS_SBJson.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMResultSet.h"

NSString* cacheKeyForGroup2(NSArray* fields, KCSReduceFunction* function, KCSQuery* condition)
{
    NSMutableString* representation = [NSMutableString string];
    for (NSString* field in fields) {
        [representation appendString:field];
    }
    [representation appendString:[function JSONStringRepresentationForFunction:fields]];
    if (condition != nil) {
        [representation appendString:[condition JSONStringRepresentation]];
    }
    return representation;
}

@interface KCSEntityCache2 ()
@property (nonatomic, strong) FMDatabase* db;
@end

@interface KCSCacheValueDB : NSObject
@property (nonatomic) NSUInteger count;
@property (retain, nonatomic) NSDictionary* object;
@property (nonatomic) BOOL unsaved;
@property (nonatomic, strong) NSDate* lastSavedTime;
@property (nonatomic, strong) NSString* objId;
@property (nonatomic, strong) NSString* classname;
@end
@implementation KCSCacheValueDB

- (instancetype) init
{
    self = [super init];
    if (self) {
        _count = 1;
        _lastSavedTime = [NSDate date];
    }
    return self;
}

- (NSDictionary*) parameterDict
{
    KCS_SBJsonWriter* writer = [[KCS_SBJsonWriter alloc] init];
    NSError* error = nil;
    NSString* object = [writer stringWithObject:_object error:&error];
    //TODO #6 - do something with error
    return @{@"id": _objId, @"obj" : object, @"time" : _lastSavedTime, @"dirty" : @(_unsaved), @"count" : @(_count), @"classname" : _classname};
}
//TODO: lmt, 

@end

@implementation KCSEntityCache2
//TODO #21 formalize this
#define VERSION @"0.0"

- (NSString*) dbPath
{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.sqllite", _persistenceId]];
}

- (instancetype) initWithPersistenceId:(NSString*)key
{
    self = [super init];
    if (self) {
        _persistenceId = key;
        
        [self initDB];
    }
    return self;
}

- (instancetype) init
{
    //TODO #18 - no blank inits
    return [self initWithPersistenceId:@"null"];
}

- (void) initDB
{
    //TODO: #19 handle errors
    //TODO: #20 deal with old db

    NSString* path = [self dbPath];
    _db = [FMDatabase databaseWithPath:path];
    if (![_db open]) return;


    
    BOOL e = NO;
    if (![_db tableExists:@"metadata"]) {
        e = [_db executeUpdate:@"CREATE TABLE metadata (id VARCHAR(255) PRIMARY KEY, version VARCHAR(255), time TEXT, data)"];
        if ([_db hadError]) { KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);}
        e = [_db executeUpdate:@"INSERT INTO metadata VALUES (:id, :version, :time)" withArgumentsInArray:@[@"1", VERSION, @"2"]];
        if ([_db hadError]) { KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);}
    } else {
        FMResultSet *rs = [_db executeQuery:@"SELECT version FROM metadata"];
        if ([_db hadError]) { KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);}
        NSString* version = nil;
        if ([rs next]) {
            NSDictionary* d = [rs resultDictionary];
            version = d[@"version"];
        }
        
        if ([version isEqualToString:VERSION] == NO) {
            //TODO: #20 deal with old db        }
        }
        
        
        
    }

    if (![_db tableExists:@"objs"]) {
        e = [_db executeUpdate:@"CREATE TABLE objs (id VARCHAR(255) PRIMARY KEY, obj TEXT, time VARCHAR(255), saved BOOL, count INT, classname TEXT)"];
        if (e == NO) {
            KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
        }
    }
    if (![_db tableExists:@"queries"]) {
        e = [_db executeUpdate:@"CREATE TABLE queries (id VARCHAR(255) PRIMARY KEY, ids TEXT)"];
        if (e == NO) {
            KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
        }
    }
    if (![_db tableExists:@"groups"]) {
        e = [_db executeUpdate:@"CREATE TABLE groups (key TEXT PRIMARY KEY, results TEXT)"];
        if (e == NO) {
            KCSLogError(@"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
        }
    }
}
#pragma mark - objects

- (KCSCacheValueDB*) dbObjectForId:(NSString*) objId
{
    NSString* q = [NSString stringWithFormat:@"SELECT * FROM objs WHERE id='%@'", objId];
    FMResultSet* rs = [_db executeQuery:q];
    if ([_db hadError]) {
        //TODO #8 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }

    KCSCacheValueDB* val = nil;
    if ([rs next]) {
        NSDictionary* d = [rs resultDictionary];
        if (d) {
            val = [[KCSCacheValueDB alloc] init];
            val.object = [d[@"obj"] JSONValue];
            val.objId = d[@"id"];
            val.lastSavedTime = d[@"time"];
            val.unsaved = [d[@"dirty"] boolValue];
            val.count = [d[@"count"] integerValue];
            val.classname = d[@"classname"];
        }

    }
    return val;
}

- (id<KCSPersistable>) objectForId:(NSString *)objId
{
    KCSCacheValueDB* dbObj = [self dbObjectForId:objId];
    NSDictionary* objDict = dbObj.object;
    NSString* classname = dbObj.classname;
    id<KCSPersistable> obj = [KCSObjectMapper makeObjectOfType:NSClassFromString(classname) withData:objDict];
    return obj;
}

- (NSArray*) dbObjectsForIds:(NSArray*) objIds
{
    if (objIds.count == 0) return @[];
    
    NSString* q = [NSString stringWithFormat:@"SELECT * FROM objs WHERE id IN ('%@')", [objIds componentsJoinedByString:@"','"]];
    FMResultSet* rs = [_db executeQuery:q];
    if ([_db hadError]) {
        //TODO #14 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }
    
    NSMutableArray* objs = [NSMutableArray arrayWithCapacity:objIds.count];
    while ([rs next]) {
        NSDictionary* d = [rs resultDictionary];
        if (d) {
            //TODO #20 combine with above
            KCSCacheValueDB* val = [[KCSCacheValueDB alloc] init];
            val.object = [d[@"obj"] JSONValue];
            val.objId = d[@"id"];
            val.lastSavedTime = d[@"time"];
            val.unsaved = [d[@"dirty"] boolValue];
            val.count = [d[@"count"] integerValue];
            val.classname = d[@"classname"];
            [objs addObject:val];
        }
        
    }
    return objs;
}

- (void) insertDbObj:(KCSCacheValueDB*)val
{
    //TODO #4 - update LMT/saved time

    //TODO #5 - Log insert/update
    BOOL upated = [_db executeUpdate:@"REPLACE INTO objs VALUES (:id, :obj, :time, :dirty, :count, :classname)"
             withParameterDictionary:[val parameterDict]];
    if (upated == NO) {
        //TODO #5 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }
}

- (KCSCacheValueDB*) insertObj:(id<KCSPersistable>)obj
{
    NSError* error = nil;
    KCSSerializedObject* o = [KCSObjectMapper makeKinveyDictionaryFromObject:obj error:&error];
    //TODO #1 - for realises handle error
    //TODO #2 - handle references
    //TODO #3 - pass in json directly
    DBAssert(error == nil, @"%@",error);
    
    KCSCacheValueDB* val = [self dbObjectForId:[o objectId]];
    if (val) {
        val.count++;
        val.object = [o dataToSerialize];
    } else {
        val = [[KCSCacheValueDB alloc] init];
        val.object = [o dataToSerialize];
        val.objId = [o objectId];
        val.classname = NSStringFromClass([obj class]);
    }
    
    return val;
}

- (void) removeObj:(NSString*)objId
{
    KCSCacheValueDB* val = [self dbObjectForId:objId];
    val.count--;
    if (val.count == 0) {
        BOOL updated = [_db executeUpdateWithFormat:@"DELETE FROM objs WHERE id='%@'", objId];
        if (updated == NO) {
            //TODO #8 separate log channel for caching
            KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
        }
    }
}

- (void) addResult:(id<KCSPersistable>)obj
{
    NSString* objId = [(NSObject*)obj kinveyObjectId];
    //TODO #14 do less cross-serialzation, eg parse object fewer times
    if (objId != nil) {
        KCSCacheValueDB* db = [self insertObj:obj];
        [self insertDbObj:db];
        
        //TODO #a2 - [_unsavedObjs removeObject:objId];
    } else {
        KCSLogDebug(@"attempting to cache an object without a set ID");
    }
}

- (void)addResults:(NSArray *)objects
{
    for (id n in objects) {
        [self addResult:n];
    }
}

- (void) removeIds:(NSArray*)keys
{
    for (NSString* key in keys) {
        [self removeObj:key];
    }
}

#pragma mark - Queries
- (NSArray*) idsForQuery:(NSString*) queryKey
{
    NSString* q = [NSString stringWithFormat:@"SELECT ids FROM queries WHERE id='%@'", queryKey];
    NSString* result = [_db stringForQuery:q];
    if ([_db hadError]) {
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
        return @[];
    } else {
        NSError* error = nil;
        NSArray* ids = [[[KCS_SBJsonParser alloc] init] objectWithString:result error:&error];
        //TODO #7 do something with error
        return ids;
    }
    
}


- (void) removeQuery:(KCSQuery*) query
{
    NSString* queryKey = [query parameterStringRepresentation];
    NSArray* keys = [self idsForQuery:queryKey];
    [self removeIds:keys];
    BOOL updated = [_db executeUpdateWithFormat:@"DELETE FROM queries WHERE id='%@'", queryKey];
    if (updated == NO) {
        //TODO #9 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }
    //TODO #10 [self persist];
}

- (void)setResults:(NSArray *)results forQuery:(KCSQuery *)query
{
    NSString* queryKey = [query parameterStringRepresentation];

    NSMutableArray* theseIds = [NSMutableArray arrayWithCapacity:results.count];
    for (id n in results) {
        NSString* objId = [n kinveyObjectId];
        if (objId != nil) {
            [theseIds addObject:objId];
            [self addResult:n];
        }
    }

    NSArray* oldIds = [self idsForQuery:queryKey];
    if (oldIds) {
        NSMutableArray* removedIds = [theseIds mutableCopy];
        [removedIds removeObjectsInArray:oldIds];
        [self removeIds:removedIds];
    }
    
    //-add
    NSString* jsonStr = [theseIds JSONRepresentation];
    BOOL updated = [_db executeUpdate:@"REPLACE INTO queries VALUES (:id, :ids)" withArgumentsInArray:@[queryKey, jsonStr]];
    if (updated == NO) {
        //TODO #11 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }

}

//TODO #13 empty results vs not cached
- (NSArray*) resultsForQuery:(KCSQuery*)query
{
    NSString* queryKey = [query parameterStringRepresentation];
    NSArray* ids = [self idsForQuery:queryKey];
    return ids == nil ? nil : [self resultsForIds:ids];
}

- (NSArray*) resultsForIds:(NSArray*)keys
{
    NSMutableArray* vals = [NSMutableArray arrayWithCapacity:keys.count];
    for (KCSCacheValueDB* val in [self dbObjectsForIds:keys]) {
        NSDictionary* objDict = val.object;
        NSString* classname = val.classname;
        id<KCSPersistable> obj = [KCSObjectMapper makeObjectOfType:NSClassFromString(classname) withData:objDict];
        [vals addObject:obj];
    }
    return vals;
}

//TODO #12 - force delete for when items are DELETED from the store

#pragma mark - Grouping
- (void)setResults:(KCSGroup *)results forGroup:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition
{
    NSString* key = cacheKeyForGroup2(fields, function, condition);
    NSDictionary* jdict = [results dictionaryValue];
    NSString* jsonStr = [jdict JSONRepresentation];
    BOOL updated = [_db executeUpdate:@"REPLACE INTO groups VALUES (:key, :results)" withArgumentsInArray:@[key, jsonStr]];
    if (updated == NO) {
        //TODO #22 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }
//TODO #23 [self persist];
}

- (void)removeGroup:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition
{
    NSString* key = cacheKeyForGroup2(fields, function, condition);
    NSString* q = [NSString stringWithFormat:@"DELETE FROM groups WHERE key='%@'", key];
    BOOL updated = [_db executeUpdate:q];
    if (updated == NO) {
        //TODO #25 separate log channel for caching
        KCSLogError(@"Cache error %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);
    }
    //TODO #24 [self persist];
}
//TODO #26 actually do grouping caching

#pragma mark - Saving
- (void) addUnsavedObject:(id)obj
{
    NSString* objId = [obj kinveyObjectId];
    if (objId == nil) {
        objId = KCSMongoObjectId();
        KCSLogDebug(@"attempting to save a new object to the backend - assigning '%@' as _id", objId);
        [obj setKinveyObjectId:objId];
    }
    if (objId != nil) {
        //TODO #22 combine with add query result
        KCSCacheValueDB* val = [self insertObj:obj];
        val.unsaved = YES;
        val.lastSavedTime = [NSDate date];
        //TODO #21 [_unsavedObjs addObject:objId];
        [self insertDbObj:val];
    } else {
        KCSLogDebug(@"attempting to cache an object without a set ID");
    }
    
}


#pragma mark - Management
- (void) clearCaches
{
    //TODO #14 - actually clear the cache
    [_db close];
    
    NSError* error = nil;
    
    NSURL* url = [NSURL fileURLWithPath:[self dbPath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    }
    DBAssert(!error, @"error clearing cache: %@", error);
    
    [self initDB];
}
@end
