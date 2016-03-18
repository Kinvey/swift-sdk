//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVCache)
public protocol Cache {
    
    var persistenceId: String { get set }
    var collectionName: String { get set }
    var ttl: NSTimeInterval { get set }
    
    func saveEntity(entity: JsonDictionary)
    
    func saveEntities(entities: [JsonDictionary])
    
    func findEntity(objectId: String) -> JsonDictionary?
    
    func findEntityByQuery(query: Query) -> [JsonDictionary]
    
    func findIdsLmtsByQuery(query: Query) -> [String : NSDate]
    
    func findAll() -> [JsonDictionary]
    
    func count() -> UInt
    
    func removeEntity(entity: JsonDictionary)
    
    func removeEntitiesByQuery(query: Query) -> UInt
    
    func removeAllEntities()
    
}

extension Cache {
    
    func isEmpty() -> Bool {
        return count() == 0
    }
    
}
