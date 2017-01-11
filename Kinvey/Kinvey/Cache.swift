//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol CacheType {
    
    var persistenceId: String { get }
    var collectionName: String { get }
    var ttl: TimeInterval? { get set }
    
    associatedtype `Type`
    
    func saveEntity(_ entity: Type)
    
    func saveEntities(_ entities: [Type])
    
    func findEntity(_ objectId: String) -> Type?
    
    func findEntityByQuery(_ query: Query) -> [Type]
    
    func findIdsLmtsByQuery(_ query: Query) -> [String : String]
    
    func findAll() -> [Type]
    
    func count(_ query: Query?) -> Int
    
    func removeEntity(_ entity: Type) -> Bool
    
    func removeEntities(_ entity: [Type]) -> Bool
    
    func removeEntitiesByQuery(_ query: Query) -> Int
    
    func removeAllEntities()
    
}

extension CacheType {
    
    func isEmpty() -> Bool {
        return count(nil) == 0
    }
    
}

internal class Cache<T: Persistable>: CacheType where T: NSObject {
    
    internal typealias `Type` = T
    
    let persistenceId: String
    let collectionName: String
    var ttl: TimeInterval?
    
    init(persistenceId: String, ttl: TimeInterval? = nil) {
        self.persistenceId = persistenceId
        self.collectionName = T.collectionName()
        self.ttl = ttl
    }
    
    func detach(_ entity: [T], query: Query) -> [T] {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func saveEntity(_ entity: T) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func saveEntities(_ entities: [T]) {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func findEntity(_ objectId: String) -> T? {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func findEntityByQuery(_ query: Query) -> [T] {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func findIdsLmtsByQuery(_ query: Query) -> [String : String] {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func findAll() -> [T] {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    func count(_ query: Query? = nil) -> Int {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    @discardableResult
    func removeEntity(_ entity: T) -> Bool {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    @discardableResult
    func removeEntities(_ entity: [T]) -> Bool {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    @discardableResult
    func removeEntitiesByQuery(_ query: Query) -> Int {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    @discardableResult
    func removeAllEntities() {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
}
