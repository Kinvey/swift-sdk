//
//  RealmCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

internal class RealmCache<T: Persistable where T: NSObject>: Cache<T>, Sync {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let operationQueue: NSOperationQueue
    let thread: NSThread
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String) {
        if !(T.self is Entity.Type) {
            preconditionFailure("\(T.self) needs to be a Entity")
        }
        realm = try! Realm()
        let className = NSStringFromClass(T.self).componentsSeparatedByString(".").last!
        objectSchema = realm.schema[className]!
        propertyNames = objectSchema.properties.map { return $0.name }
        operationQueue = NSOperationQueue.currentQueue()!
        thread = NSThread.currentThread()
        print("\(realm.configuration.fileURL!.path!)")
        super.init(persistenceId: persistenceId)
    }
    
    private func execute(block: () -> Void) {
        if thread == NSThread.currentThread() {
            block()
        } else {
            operationQueue.addOperationWithBlock(block)
            operationQueue.waitUntilAllOperationsAreFinished()
        }
    }
    
    private func results(query: Query) -> Results<Entity> {
        var realmResults = self.realm.objects(self.entityType)
        if let predicate = query.predicate {
            realmResults = realmResults.filter(predicate)
        }
        if let sortDescriptors = query.sortDescriptors {
            for sortDescriptor in sortDescriptors {
                realmResults = realmResults.sorted(sortDescriptor.key!, ascending: sortDescriptor.ascending)
            }
        }
        return realmResults
    }
    
    override func detach(entity: T) -> T {
        let json = entity.dictionaryWithValuesForKeys(propertyNames)
        return T(JSON: json)!
    }
    
    override func detach(array: [T]) -> [T] {
        var results = [T]()
        for entity in array {
            results.append(detach(entity))
        }
        return results
    }
    
    override func saveEntity(entity: T) {
        execute {
            try! self.realm.write {
                self.realm.add(entity as! Entity)
            }
        }
    }
    
    override func findEntityByQuery(query: Query) -> [T] {
        var results = [T]()
        execute {
            results = (RealmResultsArray<Entity>(self.results(query)) as NSArray) as! [T]
        }
        return results
    }
    
    override func removeEntities(entities: [T]) -> Bool {
        var result = false
        execute {
            try! self.realm.write {
                self.realm.delete(entities.map { $0 as! Entity })
            }
            result = true
        }
        return result
    }
    
    override func removeEntitiesByQuery(query: Query) -> UInt {
        var result = UInt(0)
        execute {
            try! self.realm.write {
                let results = self.results(query)
                result = UInt(results.count)
                self.realm.delete(results)
            }
        }
        return result
    }
    
    func createPendingOperation(request: NSURLRequest!, objectId: String?) -> PendingOperation {
        return RealmPendingOperation(objectId: objectId)
    }
    
    func savePendingOperation(pendingOperation: PendingOperation) {
        
    }
    
    func pendingOperations() -> [PendingOperation] {
        var results = [RealmPendingOperation]()
        execute {
            let realmResults = self.realm.objects(RealmPendingOperation.self)
            results = (RealmResultsArray<RealmPendingOperation>(realmResults) as NSArray) as! [RealmPendingOperation]
        }
        return results
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

internal class RealmPendingOperation: Object, PendingOperation {
    
    dynamic var objectId: String?
    
    init(objectId: String?) {
        self.objectId = objectId
        super.init()
    }
    
    required init() {
        super.init()
    }
    
    required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    func buildRequest() -> NSMutableURLRequest {
        return NSMutableURLRequest()
    }
    
}
