//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol CacheProtocol {
    
    var persistenceId: String { get set }
    var collectionName: String { get set }
    var ttl: NSTimeInterval { get set }
    
    associatedtype Type
    
    func saveEntity(entity: Type)
    
    func saveEntities(entities: [Type])
    
    func findEntity(objectId: String) -> Type?
    
    func findEntityByQuery(query: Query) -> [Type]
    
    func findIdsLmtsByQuery(query: Query) -> [String : String]
    
    func findAll() -> [Type]
    
    func count() -> UInt
    
    func removeEntity(entity: Type) -> Bool
    
    func removeEntitiesByQuery(query: Query) -> UInt
    
    func removeAllEntities()
    
}

extension CacheProtocol {
    
    func isEmpty() -> Bool {
        return count() == 0
    }
    
}

internal class Cache<T: Persistable>: CacheProtocol {
    
    internal typealias Type = T
    
    var persistenceId: String
    var collectionName: String
    var ttl: NSTimeInterval
    
    init(persistenceId: String, ttl: NSTimeInterval = DBL_MAX) {
        self.persistenceId = persistenceId
        self.collectionName = T.kinveyCollectionName
        self.ttl = ttl
    }
    
    func saveEntity(entity: Type) {
    }
    
    func saveEntities(entities: [Type]) {
    }
    
    func findEntity(objectId: String) -> Type? {
        return nil
    }
    
    func findEntityByQuery(query: Query) -> [Type] {
        return []
    }
    
    func findIdsLmtsByQuery(query: Query) -> [String : String] {
        return [:]
    }
    
    func findAll() -> [Type] {
        return []
    }
    
    func count() -> UInt {
        return 0
    }
    
    func removeEntity(entity: Type) -> Bool {
        return false
    }
    
    func removeEntitiesByQuery(query: Query) -> UInt {
        return 0
    }
    
    func removeAllEntities() {
    }
    
}
