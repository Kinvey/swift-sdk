//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(KCSCache)
protocol Cache {
    
    var persistenceId: String { get set }
    var collectionName: String { get set }
    
    init!(persistenceId: String, collectionName: String)
    
    func saveEntity(entity: JsonDictionary)
    
    func saveEntities(entities: [JsonDictionary])
    
    func findEntity(objectId: String) -> JsonDictionary?
    
    func findEntityByQuery(query: Query) -> [JsonDictionary]
    
    func findAll() -> [JsonDictionary]
    
    func removeEntity(entity: JsonDictionary)
    
    func removeEntitiesByQuery(query: Query) -> UInt
    
    func removeAllEntities()
    
}
