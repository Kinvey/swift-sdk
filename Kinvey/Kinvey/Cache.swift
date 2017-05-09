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
    
    func save(entity: Type)
    
    func save(entities: [Type])
    
    func find(byId objectId: String) -> Type?
    
    func find(byQuery query: Query) -> [Type]
    
    func findIdsLmts(byQuery query: Query) -> [String : String]
    
    func count(query: Query?) -> Int
    
    @discardableResult
    func remove(entity: Type) -> Bool
    
    @discardableResult
    func remove(entities: [Type]) -> Bool
    
    @discardableResult
    func remove(byQuery query: Query) -> Int
    
    func clear(query: Query?)
    
    func detach(entities: [Type], query: Query?) -> [Type]
    
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
    
    private let _getTTL: () -> TimeInterval?
    private let _setTTL: (TimeInterval?) -> Void
    private let _saveEntity: (T) -> Void
    private let _saveEntities: ([T]) -> Void
    private let _findById: (String) -> T?
    private let _findByQuery: (Query) -> [T]
    private let _findIdsLmtsByQuery: (Query) -> [String : String]
    private let _count: (Query?) -> Int
    private let _removeEntity: (T) -> Bool
    private let _removeEntities: ([T]) -> Bool
    private let _removeByQuery: (Query) -> Int
    private let _clear: (Query?) -> Void
    private let _detach: ([T], Query?) -> [T]
    
    typealias `Type` = T

    init<Cache: CacheType>(_ cache: Cache) where Cache.`Type` == T {
        _getTTL = { return cache.ttl }
        _setTTL = { cache.ttl = $0 }
        _saveEntity = cache.save(entity:)
        _saveEntities = cache.save(entities:)
        _findById = cache.find(byId:)
        _findByQuery = cache.find(byQuery:)
        _findIdsLmtsByQuery = cache.findIdsLmts(byQuery:)
        _count = cache.count(query:)
        _removeEntity = cache.remove(entity:)
        _removeEntities = cache.remove(entities:)
        _removeByQuery = cache.remove(byQuery:)
        _clear = cache.clear(query:)
        _detach = cache.detach(entities: query:)
    }
    
    func save(entity: T) {
        _saveEntity(entity)
    }
    
    func save(entities: [T]) {
        _saveEntities(entities)
    }
    
    func find(byId objectId: String) -> T? {
        return _findById(objectId)
    }
    
    func find(byQuery query: Query) -> [T] {
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
    func remove(entities: [T]) -> Bool {
        return _removeEntities(entities)
    }
    
    @discardableResult
    func remove(byQuery query: Query) -> Int {
        return _removeByQuery(query)
    }
    
    func clear(query: Query?) {
        _clear(query)
    }
    
    func detach(entities: [T], query: Query?) -> [T] {
        return _detach(entities, query)
    }
    
}
