//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVOperation)
public class Operation: NSObject {
    
    typealias ArrayCompletionHandler = ([Persistable]?, ErrorType?) -> Void
    typealias ObjectCompletionHandler = (Persistable?, ErrorType?) -> Void
    typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [Persistable]?, ErrorType?) -> Void
    
    let persistableType: Persistable.Type
    let cache: Cache
    let client: Client
    
    init(persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.persistableType = persistableType
        self.cache = cache
        self.client = client
    }
    
    func fromJson(json: [String : AnyObject]) -> Persistable {
        let objType = persistableType as! NSObject.Type
        let obj = objType.init() as! Persistable
        for key in persistableType.kinveyPropertyMapping().keys {
            var value = json[key]
            if value is NSNull {
                value = nil
            }
            obj[key] = value
        }
        return obj
    }
    
    func fromJson(jsonArray jsonArray: [JsonDictionary]) -> [Persistable] {
        var results = [Persistable]()
        for json in jsonArray {
            let obj = fromJson(json)
            results.append(obj)
        }
        return results
    }
    
    func toJson(array: [Persistable]) -> [JsonDictionary] {
        var entities = [[String : AnyObject]]()
        let keys = persistableType.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        for obj in array {
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
    func fillObject(persistable: Persistable) -> Persistable {
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
    
    func merge(persistable: Persistable, json: [String : AnyObject]) -> [String : AnyObject] {
        var persistableJson = persistable.toJson()
        if persistableType.kmdKey == nil {
            persistableJson[PersistableMetadataKey] = json[PersistableMetadataKey]
            if var kmd = persistableJson[PersistableMetadataKey] as? [String : AnyObject] {
                if let lmt = kmd[Metadata.LmtKey] as? String {
                    kmd[Metadata.LmtKey] = lmt.toDate()
                }
                if let ect = kmd[Metadata.EctKey] as? String {
                    kmd[Metadata.EctKey] = ect.toDate()
                }
                persistableJson[PersistableMetadataKey] = kmd
            }
        }
        if persistableType.aclKey == nil {
            persistableJson[PersistableAclKey] = json[PersistableAclKey]
        }
        return persistableJson
    }
    
}
