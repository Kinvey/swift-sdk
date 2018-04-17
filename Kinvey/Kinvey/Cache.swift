//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol CacheType: class {
    
    var ttl: TimeInterval? { get set }
    
    associatedtype `Type`: Persistable
    typealias SyncQuery = (query: Query, lastSync: Date)
    
    var dynamic: DynamicCacheType? { get }
    
    func save(entity: Type)
    
    func save(entities: AnyRandomAccessCollection<Type>, syncQuery: SyncQuery?)
    
    func find(byId objectId: String) -> Type?
    
    func find(byQuery query: Query) -> AnyRandomAccessCollection<Type>
    
    func findIdsLmts(byQuery query: Query) -> [String : String]
    
    func count(query: Query?) -> Int
    
    @discardableResult
    func remove(entity: Type) -> Bool
    
    @discardableResult
    func remove(entities: AnyRandomAccessCollection<Type>) -> Bool
    
    @discardableResult
    func remove(byQuery query: Query) -> Int
    
    func clear(query: Query?)
    
    func detach(entities: AnyRandomAccessCollection<Type>, query: Query?) -> AnyRandomAccessCollection<Type>

    func lastSync(query: Query) -> Date?
    
    @discardableResult
    func invalidateLastSync(query: Query) -> Date?
    
    func observe(_ query: Query?, completionHandler: @escaping (CollectionChange<AnyRandomAccessCollection<Type>>) -> Void) -> AnyNotificationToken
    
}

public protocol NotificationToken {
    
    func invalidate()
    
}

public class AnyNotificationToken: NotificationToken {
    
    private let _invalidate: () -> Void
    
    init<NotificationTokenType: NotificationToken>(_ notificationToken: NotificationTokenType) {
        self._invalidate = notificationToken.invalidate
    }
    
    public func invalidate() {
        _invalidate()
    }
    
}

internal protocol DynamicCacheType: class {
    
    func save(entities: AnyRandomAccessCollection<JsonDictionary>, syncQuery: CacheType.SyncQuery?)
    
}

extension CacheType {
    
    func isEmpty() -> Bool {
        return count(query: nil) == 0
    }
    
}

internal class Cache<T: Persistable> where T: NSObject {
    
    internal typealias `Type` = T
    
    let persistenceId: String
    let collectionName: String
    var ttl: TimeInterval?
    
    init(persistenceId: String, ttl: TimeInterval? = nil) {
        self.persistenceId = persistenceId
        self.collectionName = T.collectionName()
        self.ttl = ttl
    }
    
}

class AnyCache<T: Persistable>: CacheType {
    
    var ttl: TimeInterval? {
        get {
            return _getTTL()
        }
        set {
            _setTTL(newValue)
        }
    }
    
    var dynamic: DynamicCacheType? {
        return _getDynamic()
    }
    
    private let _getDynamic: () -> DynamicCacheType?
    private let _getTTL: () -> TimeInterval?
    private let _setTTL: (TimeInterval?) -> Void
    private let _saveEntity: (T) -> Void
    private let _saveEntities: (AnyRandomAccessCollection<Type>, SyncQuery?) -> Void
    private let _findById: (String) -> T?
    private let _findByQuery: (Query) -> AnyRandomAccessCollection<Type>
    private let _findIdsLmtsByQuery: (Query) -> [String : String]
    private let _count: (Query?) -> Int
    private let _removeEntity: (T) -> Bool
    private let _removeEntities: (AnyRandomAccessCollection<Type>) -> Bool
    private let _removeByQuery: (Query) -> Int
    private let _clear: (Query?) -> Void
    private let _detach: (AnyRandomAccessCollection<Type>, Query?) -> AnyRandomAccessCollection<Type>
    private let _lastSync: (Query) -> Date?
    private let _invalidateLastSync: (Query) -> Date?
    private let _observe: (Query?, @escaping (CollectionChange<AnyRandomAccessCollection<T>>) -> Void) -> AnyNotificationToken
    
    typealias `Type` = T
    
    let cache: Any

    init<Cache: CacheType>(_ cache: Cache) where Cache.`Type` == T {
        self.cache = cache
        _getDynamic = { return cache.dynamic }
        _getTTL = { return cache.ttl }
        _setTTL = { cache.ttl = $0 }
        _saveEntity = cache.save(entity:)
        _saveEntities = cache.save(entities: syncQuery:)
        _findById = cache.find(byId:)
        _findByQuery = cache.find(byQuery:)
        _findIdsLmtsByQuery = cache.findIdsLmts(byQuery:)
        _count = cache.count(query:)
        _removeEntity = cache.remove(entity:)
        _removeEntities = cache.remove(entities:)
        _removeByQuery = cache.remove(byQuery:)
        _clear = cache.clear(query:)
        _detach = cache.detach(entities: query:)
        _lastSync = cache.lastSync(query:)
        _invalidateLastSync = cache.invalidateLastSync(query:)
        _observe = cache.observe(_:completionHandler:)
    }
    
    func save(entity: T) {
        _saveEntity(entity)
    }
    
    func save(entities: AnyRandomAccessCollection<Type>, syncQuery: SyncQuery?) {
        _saveEntities(entities, syncQuery)
    }
    
    func find(byId objectId: String) -> T? {
        return _findById(objectId)
    }
    
    func find(byQuery query: Query) -> AnyRandomAccessCollection<Type> {
        return _findByQuery(query)
    }
    
    func findIdsLmts(byQuery query: Query) -> [String : String] {
        return _findIdsLmtsByQuery(query)
    }
    
    func count(query: Query?) -> Int {
        return _count(query)
    }
    
    @discardableResult
    func remove(entity: T) -> Bool {
        return _removeEntity(entity)
    }
    
    @discardableResult
    func remove(entities: AnyRandomAccessCollection<Type>) -> Bool {
        return _removeEntities(entities)
    }
    
    @discardableResult
    func remove(byQuery query: Query) -> Int {
        return _removeByQuery(query)
    }
    
    func clear(query: Query?) {
        _clear(query)
    }
    
    func detach(entities: AnyRandomAccessCollection<Type>, query: Query?) -> AnyRandomAccessCollection<Type> {
        return _detach(entities, query)
    }
    
    func lastSync(query: Query) -> Date? {
        return _lastSync(query)
    }
    
    @discardableResult
    func invalidateLastSync(query: Query) -> Date? {
        return _invalidateLastSync(query)
    }
    
    func observe(_ query: Query?, completionHandler: @escaping (CollectionChange<AnyRandomAccessCollection<T>>) -> Void) -> AnyNotificationToken {
        return _observe(query, completionHandler)
    }
    
}
