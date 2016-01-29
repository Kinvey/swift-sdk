//
//  LocalAppDataExecutorStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit
import PromiseKit

class LocalAppDataExecutorStrategy<T: Persistable where T: NSObject>: AppDataExecutorStrategy<T> {
    
    private let client: Client
    private let cache: Cache?
    private let sync: Sync?
    private let collectionName: String
    
    init(client: Client, cache: Cache?, sync: Sync?) {
        self.client = client
        self.cache = cache
        self.sync = sync
        self.collectionName = T.kinveyCollectionName()
    }
    
    override func get(id: String, completionHandler: DataStore<T>.ObjectCompletionHandler?) -> Request {
        let json = cache?.findEntity(id)
        let request = LocalRequest()
        Promise<T> { fulfill, reject in
            request.execute() { data, response, error in
                if let json = json {
                    let persistable = self.fromJson(json)
                    fulfill(persistable)
                } else if let error = error {
                    reject(error)
                } else {
                    abort()
                }
            }
        }.then { persistable in
            completionHandler?(persistable, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    override func find(query: Query, completionHandler: DataStore<T>.ArrayCompletionHandler?) -> Request {
        let json = cache?.findEntityByQuery(query)
        let request = LocalRequest()
        Promise<[T]> { fulfill, reject in
            request.execute() { data, response, error in
                if let json = json {
                    fulfill(self.fromJson(json))
                } else if let error = error {
                    reject(error)
                } else {
                    abort()
                }
            }
        }.then { results in
            completionHandler?(results, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    override func save(persistable: T, completionHandler: DataStore<T>.ObjectCompletionHandler?) -> Request {
        let request = LocalRequest {
            let request = self.client.networkRequestFactory.buildAppDataSave(collectionName: self.collectionName, persistable: persistable) as! HttpRequest
            
            let persistable = self.fillObject(persistable)
            var json = persistable.toJson()
            json = self.fillJson(json)
            self.cache?.saveEntity(json)
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: persistable.kinveyObjectId))
            }
        }
        Promise<T> { fulfill, reject in
            request.execute { (data, response, error) -> Void in
                if let error = error {
                    reject(error)
                } else {
                    fulfill(persistable)
                }
            }
        }.then { persistable in
            completionHandler?(persistable, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    override func remove(query: Query, completionHandler: DataStore<T>.UIntCompletionHandler?) -> Request {
        let count = self.cache?.removeEntitiesByQuery(query)
        let request = LocalRequest() {
            let request = self.client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: self.collectionName, query: query) as? HttpRequest
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(request!.request, objectId: nil))
            }
        }
        request.execute() { data, response, error in
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
        return request
    }
    
    private func fillObject(persistable: T) -> T {
        if persistable.kinveyObjectId == nil {
            persistable.kinveyObjectId = NSUUID().UUIDString
        }
        if persistable.kinveyAcl == nil, let activeUser = client.activeUser {
            persistable.kinveyAcl = Acl(creator: activeUser.userId)
        }
        return persistable
    }

    private func fillJson(var json: [String : AnyObject]) -> [String : AnyObject] {
        if let user = client.activeUser {
            if var acl = json[PersistableAclKey] as? [String : AnyObject] where acl[Acl.CreatorKey] as? String == nil {
                acl[Acl.CreatorKey] = user.userId
            } else {
                json[PersistableAclKey] = [Acl.CreatorKey : user.userId]
            }
        }
        return json
    }
    
    override func push(completionHandler: DataStore<T>.UIntCompletionHandler?) throws {
        guard let pendingOperations = self.sync?.pendingOperations() else {
            fatalError("Invalid operation")
        }
        
        var promises: [Promise<NSData>] = []
        for pendingOperation in pendingOperations {
            let request = HttpRequest(request: pendingOperation.buildRequest(), client: client)
            promises.append(Promise<NSData> { fulfill, reject in
                request.execute() { data, response, error in
                    if let response = response, let data = data where response.isResponseOK && error == nil {
                        let json = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                        if let cache = self.cache, let json = json, let pendindObjectId = pendingOperation.objectId {
                            let entity = cache.findEntity(pendindObjectId)
                            cache.removeEntity(entity)
                            
                            let persistable: T = T.fromJson(entity: json)
                            var persistableJson = persistable.toJson()
                            if T.kmdKey == nil {
                                persistableJson[PersistableMetadataKey] = json[PersistableMetadataKey]
                            }
                            if T.aclKey == nil {
                                persistableJson[PersistableAclKey] = json[PersistableAclKey]
                            }
                            cache.saveEntity(persistableJson)
                        }
                        self.sync?.removePendingOperation(pendingOperation)
                        fulfill(data)
                    } else if let error = error {
                        reject(error)
                    } else {
                        reject(Error.InvalidResponse)
                    }
                }
            })
        }
        when(promises).then { results in
            completionHandler?(UInt(results.count), nil)
        }.error { error in
            completionHandler?(nil, error as NSError)
        }
    }
    
    override func pull(query: Query, completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) throws {
    }
    
    override func sync(query: Query, completionHandler: DataStore<T>.UIntArrayCompletionHandler?) throws {
        try push() { count, error in
            if let count = count where error == nil {
                do {
                    try self.pull(query) { results, error in
                        completionHandler?(count, results, error)
                    }
                } catch let error as NSError {
                    completionHandler?(count, nil, error)
                }
            }
        }
    }
    
    override func purge() throws {
        guard let sync = sync else {
            fatalError("Invalid operation")
        }
        sync.removeAllPendingOperations()
    }
    
}
