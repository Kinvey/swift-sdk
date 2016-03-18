//
//  EmptySync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

@objc
class EmptyCache: NSObject, Cache {
    
    var persistenceId: String
    var collectionName: String
    var ttl: NSTimeInterval
    
    override init() {
        persistenceId = ""
        collectionName = ""
        ttl = 0
    }
    
    func saveEntity(entity: JsonDictionary) {
    }
    
    func saveEntities(entities: [JsonDictionary]) {
    }
    
    func findEntity(objectId: String) -> JsonDictionary? {
        return nil
    }
    
    func findEntityByQuery(query: Query) -> [JsonDictionary] {
        return []
    }
    
    func findIdsLmtsByQuery(query: Query) -> [String : NSDate] {
        return [:]
    }
    
    func findAll() -> [JsonDictionary] {
        return []
    }
    
    func count() -> UInt {
        return 0
    }
    
    func removeEntity(entity: JsonDictionary) {
    }
    
    func removeEntitiesByQuery(query: Query) -> UInt {
        return 0
    }
    
    func removeAllEntities() {
    }
    
}

@objc
class EmptySync: NSObject, Sync {
    
    var persistenceId: String
    var collectionName: String
    
    override convenience init() {
        self.init(persistenceId: "", collectionName: "")
    }
    
    required init(persistenceId: String, collectionName: String) {
        self.persistenceId = persistenceId
        self.collectionName = collectionName
    }
    
    func createPendingOperation(request: NSURLRequest!, objectId: String?) -> PendingOperation {
        return EmptyPendingOperation()
    }
    
    func savePendingOperation(pendingOperation: PendingOperation) {
    }
    
    func pendingOperations() -> [PendingOperation] {
        return []
    }
    
    func pendingOperations(objectId: String?) -> [PendingOperation] {
        return []
    }
    
    func removePendingOperation(pendingOperation: PendingOperation) {
    }
    
    func removeAllPendingOperations() {
    }
    
    func removeAllPendingOperations(objectId: String?) {
    }
    
}

@objc
class EmptyPendingOperation: NSObject, PendingOperation {
    
    var objectId: String?
    
    func buildRequest() -> NSURLRequest {
        return NSURLRequest()
    }
    
}
