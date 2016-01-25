//
//  SyncedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class SyncedStore<T: Persistable> {
    
//    internal override init(client: Client = Kinvey.sharedClient, readPolicy: ReadPolicy = .PreferLocal) {
//        super.init(client: client, readPolicy: readPolicy)
//    }
//    
//    public override func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
//        let json = self.cache.findEntity(id)
//        let request = LocalRequest()
//        request.execute() { data, response, error in
//            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), error)
//        }
//        return request
//    }
//    
//    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request {
//        let json = self.cache.findEntityByQuery(KCSQueryAdapter(query: query))
//        let request = LocalRequest()
//        request.execute() { data, response, error in
//            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), error)
//        }
//        return request
//    }
//
//    private func fillObject(var persistable: T) {
//        if persistable.kinveyObjectId == nil {
//            persistable.kinveyObjectId = NSUUID().UUIDString
//        }
//        if persistable.kinveyAcl == nil, let activeUser = client.activeUser {
//            persistable.kinveyAcl = Acl(creator: activeUser.userId)
//        }
//    }
//    
//    private func fillJson(var json: [String : AnyObject]) -> [String : AnyObject] {
//        if let user = client.activeUser, let acl = json["_acl"] as? [String : AnyObject] where acl["creator"] as? String == nil {
//            if var acl = json["_acl"] as? [String : AnyObject] {
//                acl["creator"] = user.userId
//            } else {
//                json["_acl"] = ["creator" : user.userId]
//            }
//        }
//        return json
//    }
//    
//    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
//        let request = LocalRequest() {
//            let request = self.client.networkTransport.buildAppDataSave(collectionName: self.collectionName, persistable: persistable) as? HttpRequest
//            
//            self.fillObject(persistable)
//            var json = self.toJson(persistable)
//            json = self.fillJson(json)
//            self.cache.saveEntity(json)
//            
//            self.sync.savePendingOperation(self.sync.createPendingOperation(request!.request))
//        }
//        request.execute { (data, response, error) -> Void in
//            self.dispatchAsyncTo(completionHandler)?(persistable, error)
//        }
//        return request
//    }
//    
//    public override func save(array: [T], completionHandler: ArrayCompletionHandler?) {
//        var serializedArray: [[String : AnyObject]] = []
//        for obj in array {
//            fillObject(obj)
//            let json = toJson(obj)
//            fillJson(json)
//            serializedArray.append(json)
//        }
//        cache.saveEntities(serializedArray)
//        dispatchAsyncTo(completionHandler)?(array, nil)
//    }
//    
//    public override func remove(query: Query, completionHandler: UIntCompletionHandler?) -> Request {
//        let count = self.cache.removeEntitiesByQuery(KCSQueryAdapter(query: query))
//        let request = LocalRequest() {
//            let request = self.client.networkTransport.buildAppDataRemoveByQuery(collectionName: self.collectionName, query: query) as? HttpRequest
//            self.sync.savePendingOperation(self.sync.createPendingOperation(request!.request))
//        }
//        request.execute() { data, response, error in
//            self.dispatchAsyncTo(completionHandler)?(count, error)
//        }
//        return request
//    }
//    
//    func push(completionHandler: UIntCompletionHandler? = nil) {
//        let pendingOperations = self.sync.pendingOperations()
//        
//        var count = 0
//        var successCount = UInt(0)
//        let queue = NSOperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        
//        for pendingOperation in pendingOperations {
//            let request = HttpRequest(request: pendingOperation.buildRequest(), client: client)
//            request.execute() { data, response, error in
//                if let response = response where response.isResponseOK {
//                    self.sync.removePendingOperation(pendingOperation)
//                    successCount++
//                }
//                queue.addOperationWithBlock() {
//                    if ++count == pendingOperations.count {
//                        self.dispatchAsyncTo(completionHandler)?(successCount, nil)
//                    }
//                }
//            }
//        }
//    }
    
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, NSError?) -> Void
    
    func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) {
        //TODO wrap this implementation in an abstraction layer
//        var count: UInt?
//        push() { _count, error in
//            count = _count
//        }
//        let networkStore = NetworkStore<T>(client: client, cacheEnabled: true)
//        networkStore.find(query) { results, error in
//            if let results = results {
//                self.save(results) { results, error in
//                    self.dispatchAsyncTo(completionHandler)?(count, results, error)
//                }
//            }
//        }
    }
    
    func purge() {
//        sync.removeAllPendingOperations()
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
