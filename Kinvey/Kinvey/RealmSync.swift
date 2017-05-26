//
//  RealmSync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmSync<T: Persistable>: SyncType where T: NSObject {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let executor: Executor
    
    let persistenceId: String
    lazy var collectionName: String = T.collectionName()
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) {
        if !(T.self is Entity.Type) {
            fatalError("\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let fileURL = fileURL {
            configuration.fileURL = fileURL
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion
        realm = try! Realm(configuration: configuration)
        let className = NSStringFromClass(T.self).components(separatedBy: ".").last!
        objectSchema = realm.schema[className]!
        propertyNames = objectSchema.properties.map { return $0.name }
        executor = Executor()
        self.persistenceId = persistenceId
        log.debug("Sync File: \(self.realm.configuration.fileURL!.path)")
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperationType {
        return RealmPendingOperation(request: request, collectionName: T.collectionName(), objectId: objectId)
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperationType) {
        log.verbose("Saving pending operation: \(pendingOperation)")
        executor.executeAndWait {
            try! self.realm.write {
                if !pendingOperation.collectionName.isEmpty,
                    let objectId = pendingOperation.objectId
                {
                    let previousPendingOperations = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@ AND objectId == %@", pendingOperation.collectionName, objectId)
                    self.realm.delete(previousPendingOperations)
                }
                self.realm.create(RealmPendingOperation.self, value: pendingOperation, update: true)
            }
        }
    }
    
    func pendingOperations() -> AnyCollection<PendingOperationType> {
        log.verbose("Fetching pending operations")
        var results: [PendingOperationType]?
        executor.executeAndWait {
            results = self.realm.objects(RealmPendingOperation.self).map {
                return RealmPendingOperationThreadSafeReference($0)
            }
        }
        return AnyCollection(results!)
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperationType) {
        log.verbose("Removing pending operation: \(pendingOperation)")
        executor.executeAndWait {
            try! self.realm.write {
                let realmPendingOperation = (pendingOperation as! RealmPendingOperationThreadSafeReference).realmPendingOperation
                self.realm.delete(realmPendingOperation)
            }
        }
    }
    
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) {
        log.verbose("Removing pending operations by object id: \(String(describing: objectId))")
        executor.executeAndWait {
            try! self.realm.write {
                var realmResults = self.realm.objects(RealmPendingOperation.self)
                if let objectId = objectId {
                    realmResults = realmResults.filter("objectId == %@", objectId)
                }
                if let methods = methods {
                    realmResults = realmResults.filter("method in %@", methods)
                }
                self.realm.delete(realmResults)
            }
        }
    }
    
}
