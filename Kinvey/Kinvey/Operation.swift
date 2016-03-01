//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class Operation<T: Persistable where T: NSObject> {
    
    typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    let client: Client
    let cache: Cache
    
    init(cache: Cache, client: Client) {
        self.cache = cache
        self.client = client
    }
    
    func fromJson(json: [String : AnyObject]) -> T {
        let obj = T.self.init()
        for key in T.kinveyPropertyMapping().keys {
            var value = json[key]
            if value is NSNull {
                value = nil
            }
            obj[key] = value
        }
        return obj
    }
    
    func fromJson(jsonArray: [[String : AnyObject]]) -> [T] {
        var results: [T] = []
        for json in jsonArray {
            let obj = fromJson(json)
            results.append(obj)
        }
        return results
    }
    
    func toJson(array: [T]) -> [[String : AnyObject]] {
        var entities: [[String : AnyObject]] = []
        for obj in array {
            let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
    func fillObject(persistable: T) -> T {
        if persistable.kinveyObjectId == nil {
            persistable.kinveyObjectId = "\(ObjectIdTmpPrefix)\(NSUUID().UUIDString)"
        }
        if persistable.kinveyAcl == nil, let activeUser = client.activeUser {
            persistable.kinveyAcl = Acl(creator: activeUser.userId)
        }
        return persistable
    }
    
    func fillJson(var json: [String : AnyObject]) -> [String : AnyObject] {
        if let user = client.activeUser {
            if var acl = json[PersistableAclKey] as? [String : AnyObject] where acl[Acl.CreatorKey] as? String == nil {
                acl[Acl.CreatorKey] = user.userId
            } else {
                json[PersistableAclKey] = [Acl.CreatorKey : user.userId]
            }
        }
        return json
    }
    
    func merge(persistable: T, json: [String : AnyObject]) -> [String : AnyObject] {
        var persistableJson = persistable.toJson()
        if T.kmdKey == nil {
            persistableJson[PersistableMetadataKey] = json[PersistableMetadataKey]
        }
        if T.aclKey == nil {
            persistableJson[PersistableAclKey] = json[PersistableAclKey]
        }
        return persistableJson
    }
    
}
