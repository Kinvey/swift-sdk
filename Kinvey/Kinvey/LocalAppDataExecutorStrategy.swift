//
//  LocalAppDataExecutorStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class LocalAppDataExecutorStrategy<T: Persistable>: GenericAppDataExecutorStrategy<T> {
    
    private let client: Client
    private let cache: Cache
    private let sync: Sync
    private let collectionName: String
    
    init(client: Client = sharedClient, cache: Cache, sync: Sync) {
        self.client = client
        self.cache = cache
        self.sync = sync
        self.collectionName = T.kinveyCollectionName()
        super.init(nil)
    }
    
    override func get(id: String, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        let json = cache.findEntity(id)
        let request = LocalRequest()
        request.execute() { data, response, error in
            self.dispatchAsyncTo(type: T.self, completionHandler)?(self.fromJson(json), error)
        }
        return request
    }
    
    override func find(query: Query, completionHandler: Store<T>.ArrayCompletionHandler?) -> Request {
        let json = cache.findEntityByQuery(query)
        let request = LocalRequest()
        request.execute() { data, response, error in
            self.dispatchAsyncTo(type: T.self, completionHandler)?(self.fromJson(json), error)
        }
        return request
    }
    
    override func save(persistable: T, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        let request = LocalRequest() {
            let request = self.client.networkRequestFactory.buildAppDataSave(collectionName: self.collectionName, persistable: persistable) as? HttpRequest

            self.fillObject(persistable)
            var json = self.toJson(persistable)
            json = self.fillJson(json)
            self.cache.saveEntity(json)

            self.sync.savePendingOperation(self.sync.createPendingOperation(request!.request))
        }
        request.execute { (data, response, error) -> Void in
            self.dispatchAsyncTo(type: T.self, completionHandler)?(persistable, error)
        }
        return request
    }
    
    override func remove(query: Query, completionHandler: Store<T>.UIntCompletionHandler?) -> Request {
        let count = self.cache.removeEntitiesByQuery(query)
        let request = LocalRequest() {
            let request = self.client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: self.collectionName, query: query) as? HttpRequest
            self.sync.savePendingOperation(self.sync.createPendingOperation(request!.request))
        }
        request.execute() { data, response, error in
            self.dispatchAsyncTo(type: T.self, completionHandler)?(count, error)
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
    
}
