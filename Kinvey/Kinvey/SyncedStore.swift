//
//  SyncedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class SyncedStore<T: Persistable>: Store<T> {
    
    internal override init(client: Client = Kinvey.sharedClient) {
        super.init(client: client)
    }
    
    public override func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
        let json = self.entityPersistence.findEntity(id, forClass: self.clazz)
        let request = LocalRequest()
        request.execute() { data, response, error in
            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), error)
        }
        return request
    }
    
    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request {
        let json = self.entityPersistence.findEntityByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
        let request = LocalRequest()
        request.execute() { data, response, error in
            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), error)
        }
        return request
    }
    
    private func fillObject(var persistable: T) {
        if persistable.kinveyObjectId == nil {
            persistable.kinveyObjectId = NSUUID().UUIDString
        }
        if persistable.kinveyAcl == nil, let activeUser = client.activeUser {
            persistable.kinveyAcl = Acl(creator: activeUser.userId)
        }
    }
    
    private func fillJson(var json: [String : AnyObject]) -> [String : AnyObject] {
        if let user = client.activeUser, let acl = json["_acl"] as? [String : AnyObject] where acl["creator"] as? String == nil {
            if var acl = json["_acl"] as? [String : AnyObject] {
                acl["creator"] = user.userId
            } else {
                json["_acl"] = ["creator" : user.userId]
            }
        }
        return json
    }
    
    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        let request = LocalRequest() {
            let request = self.buildSaveRequest(persistable) as? HttpRequest
            
            self.fillObject(persistable)
            var json = self.toJson(persistable)
            json = self.fillJson(json)
            self.entityPersistence.saveEntity(json, forClass: self.clazz)
            
            let syncedObject = KCSURLRequestRealm(URLRequest: request!.request, collectionName: T.kinveyCollectionName(), objectId: persistable.kinveyObjectId)
            self.entityPersistence.saveEntity(syncedObject.toJson(), forClass: KCSURLRequestRealm.self)
        }
        request.execute { (data, response, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(persistable, error)
        }
        return request
    }
    
    public override func save(array: [T], completionHandler: ArrayCompletionHandler?) {
        var serializedArray: [[String : AnyObject]] = []
        for obj in array {
            fillObject(obj)
            let json = toJson(obj)
            fillJson(json)
            serializedArray.append(json)
        }
        entityPersistence.saveEntities(serializedArray, forClass: clazz)
        dispatchAsyncTo(completionHandler)?(array, nil)
    }
    
    public override func remove(query: Query, completionHandler: UIntCompletionHandler?) -> Request {
        let count = self.entityPersistence.removeEntitiesByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
        let request = LocalRequest() {
            let request = self.buildRemoveRequest(query) as? HttpRequest
            let syncedObject = KCSURLRequestRealm(URLRequest: request!.request, collectionName: T.kinveyCollectionName(), objectId: nil)
            self.entityPersistence.saveEntity(syncedObject.toJson(), forClass: KCSURLRequestRealm.self)
        }
        request.execute() { data, response, error in
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
        return request
    }
    
    func push(completionHandler: UIntCompletionHandler? = nil) {
        //TODO wrap this implementation in an abstraction layer
        let query = Query(format: "method IN %@", ["POST", "PUT", "DELETE"])
        let entities = entityPersistence.findEntityByQuery(KCSQueryAdapter(query: query), forClass: KCSURLRequestRealm.self)
        
        var count = 0
        var successCount = UInt(0)
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        for entity in entities {
            let request = HttpRequest(request: KCSURLRequestRealm(value: entity).buildRequest(), client: client)
            request.execute() { data, response, error in
                if let response = response where response.isResponseOK {
                    self.entityPersistence.removeEntity(entity, forClass: KCSURLRequestRealm.self)
                    successCount++
                }
                queue.addOperationWithBlock() {
                    if ++count == entities.count {
                        self.dispatchAsyncTo(completionHandler)?(successCount, nil)
                    }
                }
            }
        }
    }
    
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, NSError?) -> Void
    
    func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) {
        //TODO wrap this implementation in an abstraction layer
        var count: UInt?
        push() { _count, error in
            count = _count
        }
        let networkStore = NetworkStore<T>(client: client, cacheEnabled: true)
        networkStore.find(query) { results, error in
            if let results = results {
                self.save(results) { results, error in
                    self.dispatchAsyncTo(completionHandler)?(count, results, error)
                }
            }
        }
    }
    
    func purge() {
        //TODO wrap this implementation in an abstraction layer
        self.entityPersistence.removeAllEntitiesForClass(KCSURLRequestRealm.self)
    }
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: UIntArrayCompletionHandler? = nil) -> UIntArrayCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { count, objs, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(count, objs, error)
                })
            }
        }
        return completionHandler
    }

}
