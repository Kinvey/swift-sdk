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
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperation {
        return RealmPendingOperation(
            request: request,
            collectionName: collectionName,
            objectIdKind: ObjectIdKind(objectId)
        )
    }
    
    func save(pendingOperation: PendingOperation) {
        signpost(.begin, log: osLog, name: "Save PendingOperation", "Collection: %@", pendingOperation.collectionName)
        defer {
            signpost(.end, log: osLog, name: "Save PendingOperation", "Collection: %@", pendingOperation.collectionName)
        }
        executor.executeAndWait {
            try! self.realm.write {
                if !pendingOperation.collectionName.isEmpty,
                    let objectId = pendingOperation.objectId
                {
                    let previousPendingOperations = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@ AND objectId == %@", pendingOperation.collectionName, objectId)
                    self.realm.delete(previousPendingOperations)
                }
                self.realm.create(RealmPendingOperation.self, value: pendingOperation, update: .all)
            }
        }
    }
    
    func save<C>(pendingOperations: C) where C : Collection, C.Element == PendingOperation {
        signpost(.begin, log: osLog, name: "Save PendingOperation", "Collection: %@", try! T.collectionName())
        defer {
            signpost(.end, log: osLog, name: "Save PendingOperation", "Collection: %@", try! T.collectionName())
        }
        executor.executeAndWait {
            try! self.realm.write {
                pendingOperations.forEachAutoreleasepool { pendingOperation in
                    if !pendingOperation.collectionName.isEmpty,
                        let objectId = pendingOperation.objectId
                    {
                        let previousPendingOperations = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@ AND objectId == %@", pendingOperation.collectionName, objectId)
                        self.realm.delete(previousPendingOperations)
                    }
                    self.realm.create(RealmPendingOperation.self, value: pendingOperation, update: .all)
                }
            }
        }
    }
    
    func pendingOperationsCount() -> Int {
        return pendingRealmOperations().count
    }
    
    func pendingRealmOperations() -> AnyRandomAccessCollection<RealmPendingOperation> {
        return AnyRandomAccessCollection(self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@", self.collectionName))
    }
    
    func pendingOperationsReferences() -> AnyRandomAccessCollection<RealmPendingOperationReference> {
        return AnyRandomAccessCollection(pendingRealmOperations().map { pendingOperation in
            return RealmPendingOperationReference(pendingOperation)
        })
    }
    
    func pendingOperations(useMultiInsert: Bool) -> AnyRandomAccessCollection<PendingOperation> {
        log.verbose("Fetching pending operations")
        var results: [PendingOperation]!
        let collectionName = self.collectionName
        executor.executeAndWait {
            let _results = self.pendingOperationsReferences()
            guard restApiVersion >= 5, useMultiInsert else {
                results = Array(_results)
                return
            }
            results = [PendingOperation]()
            results.reserveCapacity(_results.count)
            var everythingElse = [String : PendingOperation]()
            defer {
                results.append(contentsOf: everythingElse.values)
            }
            let posts = _results.map {
                return ($0, $0.buildRequest())
            }.compactMap { (pendingOperation, urlRequest) -> (pendingOperation: RealmPendingOperationReference, url: URL, objectId: String, json: JsonDictionary)? in
                guard urlRequest.httpMethod == "POST" else {
                    everythingElse[pendingOperation.requestId] = pendingOperation
                    return nil
                }
                guard let url = urlRequest.url,
                    let objectId = pendingOperation.objectId,
                    let httpBody = urlRequest.httpBody,
                    let json = try? JSONSerialization.jsonObject(with: httpBody) as? JsonDictionary
                else {
                    return nil
                }
                return (pendingOperation: pendingOperation, url: url, objectId: objectId, json: json)
            }
            guard posts.count > 1 else {
                if let post = posts.first {
                    results.append(post.pendingOperation)
                }
                return
            }
            var result = (requestIds: [String](), urls: [URL](), objectIds: [String](), jsonArray: [JsonDictionary]())
            result.requestIds.reserveCapacity(_results.count)
            result.urls.reserveCapacity(_results.count)
            result.objectIds.reserveCapacity(_results.count)
            result.jsonArray.reserveCapacity(_results.count)
            result = posts.reduce(into: result) { (result, value) in
                result.requestIds.append(value.pendingOperation.requestId)
                result.urls.append(value.url)
                result.objectIds.append(value.objectId)
                result.jsonArray.append(value.json)
            }
            let urls = Set(result.urls)
            guard urls.count == 1,
                let url = urls.first,
                let data = try? JSONSerialization.data(withJSONObject: result.jsonArray)
            else {
                return
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue(UUID().uuidString, forHTTPHeaderField: KinveyHeaderField.requestId)
            urlRequest.httpBody = data
            results.append(
                RealmPendingOperation(
                    request: urlRequest,
                    collectionName: collectionName,
                    objectIdKind: ObjectIdKind(result.objectIds),
                    requestIds: result.requestIds
                )
            )
        }
        return AnyRandomAccessCollection(results)
    }
    
    func remove(pendingOperation: PendingOperation) {
        log.verbose("Removing pending operation: \(pendingOperation)")
        executor.executeAndWait {
            try! self.realm.write {
                guard let realmPendingOperationRef = pendingOperation as? RealmPendingOperationReference else {
                    return
                }
                self.realm.delete(realmPendingOperationRef.realmPendingOperation)
            }
        }
    }
    
    func remove<C>(requestIds: C) where C : Collection, C.Element == String {
        log.verbose("Removing \(requestIds.count) requestIds")
        executor.executeAndWait {
            try! self.realm.write {
                let objects = self.realm.objects(RealmPendingOperation.self).filter("requestId IN %@", Array(requestIds))
                self.realm.delete(objects)
            }
        }
    }
    
    func removeAllPendingOperations(_ objectId: String?, methods: [String]?) -> Int {
        signpost(.begin, log: osLog, name: "Remove All PendingOperations", "Object ID: %@", String(describing: objectId))
        defer {
            signpost(.end, log: osLog, name: "Remove All PendingOperations", "Object ID: %@", String(describing: objectId))
        }
        var count = 0
        executor.executeAndWait {
            try! self.realm.write {
                var realmResults = self.realm.objects(RealmPendingOperation.self).filter("collectionName == %@", self.collectionName)
                if let objectId = objectId {
                    realmResults = realmResults.filter("objectId == %@", objectId)
                }
                if let methods = methods {
                    realmResults = realmResults.filter("method in %@", methods)
                }
                count = realmResults.count
                self.realm.delete(realmResults)
            }
        }
        return count
    }
    
}
