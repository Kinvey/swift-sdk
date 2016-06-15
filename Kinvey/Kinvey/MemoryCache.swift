//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MemoryCache<T: Persistable>: CacheProtocol {
    
    internal typealias Type = T
    
    var persistenceId: String = ""
    var collectionName: String = ""
    var ttl: NSTimeInterval = 0
    let type: Persistable.Type
    
    var memory = [String : Type]()
    
    init(type: Persistable.Type) {
        self.type = type
    }
    
    func saveEntity(entity: Type) {
        let objId = entity[type.idKey] as! String
        memory[objId] = entity
    }
    
    func saveEntities(entities: [Type]) {
        for entity in entities {
            saveEntity(entity)
        }
    }
    
    func findEntity(objectId: String) -> Type? {
        return memory[objectId]
    }
    
    func findEntityByQuery(query: Query) -> [Type] {
        guard let predicate = query.predicate else {
            return memory.values.map({ (json) -> JsonDictionary in
                return json
            })
        }
        return memory.filter({ (key, obj) -> Bool in
            return predicate.evaluateWithObject(obj)
        }).map({ (key, obj) -> JsonDictionary in
            return obj
        })
    }
    
    func findIdsLmtsByQuery(query: Query) -> [String : String] {
        return findEntityByQuery(query).map { (entity) -> (String, NSDate) in
            let kmd = entity[type.kmdKey ?? PersistableMetadataKey] as! JsonDictionary
            return (entity[type.idKey] as! String, kmd[Metadata.LmtKey] as! NSDate)
            }.reduce([String : String](), combine: { (items, pair) in
                var items = items
                items[pair.0] = pair.1.toString()
                return items
            })
    }
    
    func findAll() -> [Type] {
        return findEntityByQuery(Query())
    }
    
    func count() -> UInt {
        return UInt(memory.count)
    }
    
    func removeEntity(entity: Type) -> Bool {
        let objId = entity[type.idKey] as! String
        return memory.removeValueForKey(objId) != nil
    }
    
    func removeEntitiesByQuery(query: Query) -> UInt {
        let objs = findEntityByQuery(query)
        for obj in objs {
            removeEntity(obj)
        }
        return UInt(objs.count)
    }
    
    func removeAllEntities() {
        memory.removeAll()
    }
    
}
