//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class Operation<T: Persistable where T: NSObject>: NSObject {
    
    typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    let cache: Cache<T>?
    let client: Client
    
    init(cache: Cache<T>? = nil, client: Client) {
        self.cache = cache
        self.client = client
    }
    
    func reduceToIdsLmts(jsonArray: [JsonDictionary]) -> [String : String] {
        var items = [String : String](minimumCapacity: jsonArray.count)
        for json in jsonArray {
            if let id = json[PersistableIdKey] as? String,
                let kmd = json[PersistableMetadataKey] as? JsonDictionary,
                let lmt = kmd[Metadata.LmtKey] as? String
            {
                items[id] = lmt
            }
        }
        return items
    }
    
    func computeDeltaSet(query: Query, refObjs: [String : String]) -> (created: Set<String>, updated: Set<String>, deleted: Set<String>) {
        guard let cache = cache else {
            return (created: Set<String>(), updated: Set<String>(), deleted: Set<String>())
        }
        let refKeys = Set<String>(refObjs.keys)
        let cachedObjs = cache.findIdsLmtsByQuery(query)
        let cachedKeys = Set<String>(cachedObjs.keys)
        let createdKeys = refKeys.subtract(cachedKeys)
        let deletedKeys = cachedKeys.subtract(refKeys)
        var updatedKeys = refKeys.intersect(cachedKeys)
        if updatedKeys.count > 0 {
            updatedKeys = Set<String>(updatedKeys.filter({ refObjs[$0] != cachedObjs[$0] }))
        }
        return (created: createdKeys, updated: updatedKeys, deleted: deletedKeys)
    }
    
    func fillObject(inout persistable: T) -> T {
        if persistable.kinveyObjectId == nil {
            persistable.kinveyObjectId = "\(ObjectIdTmpPrefix)\(NSUUID().UUIDString)"
        }
        if persistable.kinveyAcl == nil, let activeUser = client.activeUser {
            persistable.kinveyAcl = Acl(creator: activeUser.userId)
        }
        return persistable
    }
    
    func fillJson(json: [String : AnyObject]) -> [String : AnyObject] {
        return [:]
//        var json = json
//        if let user = client.activeUser {
//            let aclKey = T.kinveyAclPropertyName ?? PersistableAclKey
//            if var acl = json[aclKey] as? [String : AnyObject] where acl[Acl.CreatorKey] as? String == nil {
//                acl[Acl.CreatorKey] = user.userId
//            } else {
//                json[aclKey] = [Acl.CreatorKey : user.userId]
//            }
//        }
//        let kmdKey = persistableType.kmdKey ?? PersistableMetadataKey
//        if json[kmdKey] == nil {
//            json[kmdKey] = [Metadata.EctKey : NSDate().toString()]
//        }
//        return json
    }
    
    func merge(inout persistableArray: [T], jsonArray: [JsonDictionary]) {
        if persistableArray.count == jsonArray.count && persistableArray.count > 0 {
            for (index, _) in persistableArray.enumerate() {
                merge(&persistableArray[index], json: jsonArray[index])
            }
        }
    }
    
    func merge(inout persistable: T, json: JsonDictionary) {
        let map = Map(mappingType: .FromJSON, JSONDictionary: json)
        persistable.mapping(map)
    }
    
}
