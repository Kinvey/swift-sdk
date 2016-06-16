//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MemoryCache<T: Persistable where T: NSObject>: Cache<T> {
    
    var memory = [String : Type]()
    
    init() {
        super.init(persistenceId: "")
    }
    
    override func saveEntity(entity: Type) {
        let objId = entity[T.kinveyObjectIdPropertyName()] as! String
        memory[objId] = entity
    }
    
    override func saveEntities(entities: [Type]) {
        for entity in entities {
            saveEntity(entity)
        }
    }
    
    override func findEntity(objectId: String) -> Type? {
        return memory[objectId]
    }
    
    override func findEntityByQuery(query: Query) -> [Type] {
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
        return findEntityByQuery(query).map { (entity) -> (String, NSDate) in
            let kmd = entity[T.kinveyMetadataPropertyName() ?? PersistableMetadataKey] as! JsonDictionary
            return (entity[T.kinveyObjectIdPropertyName()] as! String, kmd[Metadata.LmtKey] as! NSDate)
            }.reduce([String : String](), combine: { (items, pair) in
                var items = items
                items[pair.0] = pair.1.toString()
                return items
            })
    }
    
    override func findAll() -> [Type] {
        return findEntityByQuery(Query())
    }
    
    override func count() -> UInt {
        return UInt(memory.count)
    }
    
    override func removeEntity(entity: Type) -> Bool {
        let objId = entity[Type.kinveyObjectIdPropertyName()] as! String
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
