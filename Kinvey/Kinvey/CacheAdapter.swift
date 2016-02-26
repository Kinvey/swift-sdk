//
//  CacheAdapter.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(KNVCacheAdapter)
class CacheAdapter: NSObject, Cache {
    
    var persistenceId: String {
        get {
            return ""
        }
        set {
            
        }
    }
    
    var collectionName: String {
        get {
            return ""
        }
        set {
            
        }
    }
    
    let cache: KCSCache
    
    init(cache: KCSCache) {
        self.cache = cache
    }
    
    func saveEntity(entity: JsonDictionary) {
        cache.saveEntity(entity)
    }
    
    func saveEntities(entities: [JsonDictionary]) {
        cache.saveEntities(entities)
    }
    
    func findEntity(objectId: String) -> JsonDictionary? {
        return cache.findEntity(objectId)
    }
    
    func findEntityByQuery(query: Query) -> [JsonDictionary] {
        return cache.findEntityByQuery(KCSQueryAdapter(query: query))
    }
    
    func findAll() -> [JsonDictionary] {
        return cache.findAll()
    }
    
    func removeEntity(entity: JsonDictionary) {
        cache.removeEntity(entity)
    }
    
    func removeEntitiesByQuery(query: Query) -> UInt {
        return cache.removeEntitiesByQuery(KCSQueryAdapter(query: query))
    }
    
    func removeAllEntities() {
        
    }
    
}
