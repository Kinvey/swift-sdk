//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MemoryCache<T: Persistable where T: NSObject>: Cache<T> {
    
    var memory = [String : T]()
    
    init() {
        super.init(persistenceId: "")
    }
    
    override func saveEntity(entity: T) {
        let objId = entity.entityId!
        memory[objId] = entity
    }
    
    override func saveEntities(entities: [T]) {
        for entity in entities {
            saveEntity(entity)
        }
    }
    
    override func findEntity(objectId: String) -> T? {
        return memory[objectId]
    }
    
    override func findEntityByQuery(query: Query) -> [T] {
        guard let predicate = query.predicate else {
            return memory.values.map({ (json) -> Type in
                return json
            })
        }
        return memory.filter({ (key, obj) -> Bool in
            return predicate.evaluateWithObject(obj)
        }).map({ (key, obj) -> Type in
            return obj
        })
    }
    
    override func findIdsLmtsByQuery(query: Query) -> [String : String] {
        var results = [String : String]()
        let array = findEntityByQuery(query).map { (entity) -> (String, String) in
            let kmd = entity.metadata!
            return (entity.entityId!, kmd.lmt!)
        }
        for item in array {
            results[item.0] = item.1
        }
        return results
    }
    
    override func findAll() -> [T] {
        return findEntityByQuery(Query())
    }
    
    override func count(query: Query? = nil) -> UInt {
        if let query = query {
            return UInt(findEntityByQuery(query).count)
        }
        return UInt(memory.count)
    }
    
    override func removeEntity(entity: T) -> Bool {
        let objId = entity.entityId!
        return memory.removeValueForKey(objId) != nil
    }
    
    override func removeEntitiesByQuery(query: Query) -> UInt {
        let objs = findEntityByQuery(query)
        for obj in objs {
            removeEntity(obj)
        }
        return UInt(objs.count)
    }
    
    override func removeAllEntities() {
        memory.removeAll()
    }
    
}
