//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

@objc
class MemoryCache: NSObject, Cache {
    
    var persistenceId: String = ""
    var collectionName: String = ""
    var ttl: NSTimeInterval = 0
    let type: Persistable.Type
    
    var memory = [String : JsonDictionary]()
    
    init(type: Persistable.Type) {
        self.type = type
    }
    
    func saveEntity(entity: JsonDictionary) {
        let objId = entity[type.idKey] as! String
        memory[objId] = entity
    }
    
    func saveEntities(entities: [JsonDictionary]) {
        for entity in entities {
            saveEntity(entity)
        }
    }
    
    func findEntity(objectId: String) -> JsonDictionary? {
        return memory[objectId]
    }
    
    func findEntityByQuery(query: Query) -> [JsonDictionary] {
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
    
    func findAll() -> [JsonDictionary] {
        return findEntityByQuery(Query())
    }
    
    func count() -> UInt {
        return UInt(memory.count)
    }
    
    func removeEntity(entity: JsonDictionary) {
        let objId = entity[type.idKey] as! String
        memory.removeValueForKey(objId)
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
