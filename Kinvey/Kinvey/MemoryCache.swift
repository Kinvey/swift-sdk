//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class MemoryCache<T: Persistable>: Cache<T>, CacheType where T: NSObject {
    
    typealias `Type` = T
    
    var memory = [String : T]()
    
    init() {
        super.init(persistenceId: "")
    }
    
    func save(entity: T) {
        let objId = entity.entityId!
        memory[objId] = entity
    }
    
    func save(entities: [T]) {
        for entity in entities {
            save(entity: entity)
        }
    }
    
    func find(byId objectId: String) -> T? {
        return memory[objectId]
    }
    
    func find(byQuery query: Query) -> [T] {
        guard let predicate = query.predicate else {
            return memory.values.map({ (json) -> Type in
                return json
            })
        }
        return memory.filter({ (key, obj) -> Bool in
            return predicate.evaluate(with: obj)
        }).map({ (key, obj) -> Type in
            return obj
        })
    }
    
    func findIdsLmts(byQuery query: Query) -> [String : String] {
        var results = [String : String]()
        let array = find(byQuery: query).map { (entity) -> (String, String) in
            let kmd = entity.metadata!
            return (entity.entityId!, kmd.lmt!)
        }
        for (key, value) in array {
            results[key] = value
        }
        return results
    }
    
    func findAll() -> [T] {
        return find(byQuery: Query())
    }
    
    func count(query: Query? = nil) -> Int {
        if let query = query {
            return find(byQuery: query).count
        }
        return memory.count
    }
    
    @discardableResult
    func remove(entity: T) -> Bool {
        let objId = entity.entityId!
        return memory.removeValue(forKey: objId) != nil
    }
    
    @discardableResult
    func remove(entities: [T]) -> Bool {
        for entity in entities {
            if !remove(entity: entity) {
                return false
            }
        }
        return true
    }
    
    @discardableResult
    func remove(byQuery query: Query) -> Int {
        let objs = find(byQuery: query)
        for obj in objs {
            remove(entity: obj)
        }
        return objs.count
    }
    
    func removeAll() {
        memory.removeAll()
    }
    
    func clear(query: Query?) {
        memory.removeAll()
    }
    
    func detach(entities: [T], query: Query?) -> [T] {
        return entities
    }
    
    func group(aggregation: Aggregation, predicate: NSPredicate?) -> [JsonDictionary] {
        return []
    }
    
}
