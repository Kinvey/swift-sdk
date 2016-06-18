//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol CacheProtocol {
    
    var persistenceId: String { get }
    var collectionName: String { get }
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

internal class Cache<T: Persistable where T: NSObject>: CacheProtocol {
    
    internal typealias Type = T
    
    let persistenceId: String
    let collectionName: String
    var ttl: NSTimeInterval
    
    init(persistenceId: String, ttl: NSTimeInterval = DBL_MAX) {
        self.persistenceId = persistenceId
        self.collectionName = T.kinveyCollectionName()
        self.ttl = ttl
    }
    
    func saveEntity(entity: T) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func saveEntities(entities: [T]) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findEntity(objectId: String) -> T? {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findEntityByQuery(query: Query) -> [T] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findIdsLmtsByQuery(query: Query) -> [String : String] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findAll() -> [T] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func count() -> UInt {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeEntity(entity: T) -> Bool {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeEntitiesByQuery(query: Query) -> UInt {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeAllEntities() {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
}
