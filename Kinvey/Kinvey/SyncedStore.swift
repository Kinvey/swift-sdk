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
        return LocalRequest() {
            let json = self.entityPersistence.findEntity(id, forClass: self.clazz)
            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), nil)
        }
    }
    
    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request {
        return LocalRequest() {
            let json = self.entityPersistence.findEntityByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
            self.dispatchAsyncTo(completionHandler)?(self.fromJson(json), nil)
        }
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
        if let user = client.activeUser {
            if json["_acl"]?["creator"] as? String == nil {
                if var acl = json["_acl"] as? [String : AnyObject] {
                    acl["creator"] = user.userId
                } else {
                    json["_acl"] = ["creator" : user.userId]
                }
            }
        }
        return json
    }
    
    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        return LocalRequest() {
            self.fillObject(persistable)
            var json = self.toJson(persistable)
            json = self.fillJson(json)
            self.entityPersistence.saveEntity(json, forClass: self.clazz)
            self.dispatchAsyncTo(completionHandler)?(persistable, nil)
        }
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
        return LocalRequest() {
            let count = self.entityPersistence.removeEntitiesByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
            self.dispatchAsyncTo(completionHandler)?(count, nil)
        }
    }
    
    func push() {
    }
    
    func sync(query: Query) {
    }
    
    func purge() {
    }

}
