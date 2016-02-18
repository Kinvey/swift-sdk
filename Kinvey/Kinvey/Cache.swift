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
    
    func saveEntity(entity: [String : AnyObject])
    
    func saveEntities(entities: [[String : AnyObject]])
    
    func findEntity(objectId: String) -> [String : AnyObject]?
    
    func findEntityByQuery(query: Query) -> [[String : AnyObject]]
    
    func findAll() -> [[String : AnyObject]]
    
    func removeEntity(entity: [String : AnyObject])
    
    func removeEntitiesByQuery(query: Query) -> UInt
    
    func removeAllEntities()
    
}
