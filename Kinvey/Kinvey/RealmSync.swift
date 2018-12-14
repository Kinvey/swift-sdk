//
//  RealmSync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

#if canImport(os)
import os
#endif

class RealmSync<T: Persistable>: SyncType where T: NSObject {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let executor: Executor
    
    let persistenceId: String
    lazy var collectionName: String = try! T.collectionName()
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) throws {
        if !(T.self is Entity.Type) {
            throw Error.invalidOperation(description: "\(T.self) needs to be a Entity")
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
        return RealmPendingOperation(request: request, collectionName: collectionName, objectId: objectId)
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperationType) {
        #if canImport(os)
        if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
            os_signpost(.begin, log: osLog, name: "Save PendingOperation", "Collection: %s", pendingOperation.collectionName)
        }
        defer {
            if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
                os_signpost(.end, log: osLog, name: "Save PendingOperation", "Collection: %s", pendingOperation.collectionName)
            }
        }
        #endif
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
            results = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@", self.collectionName).map {
                return RealmPendingOperationReference($0)
            }
        }
        return AnyCollection(results!)
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperationType) {
        log.verbose("Removing pending operation: \(pendingOperation)")
        executor.executeAndWait {
            try! self.realm.write {
                let realmPendingOperation = (pendingOperation as! RealmPendingOperationReference).realmPendingOperation
                self.realm.delete(realmPendingOperation)
            }
        }
    }
    
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) {
        #if canImport(os)
        if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
            os_signpost(.begin, log: osLog, name: "Remove All PendingOperations", "Object ID: %s", String(describing: objectId))
        }
        defer {
            if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
                os_signpost(.end, log: osLog, name: "Remove All PendingOperations", "Object ID: %s", String(describing: objectId))
            }
        }
        #endif
        executor.executeAndWait {
            try! self.realm.write {
                var realmResults = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@", self.collectionName)
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
