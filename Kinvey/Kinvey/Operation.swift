//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class Operation<T: Persistable>: NSObject {
    
    typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    let cache: Cache?
    let client: Client
    
    init(cache: Cache? = nil, client: Client) {
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
    
    func fromJson(json: [String : AnyObject]) -> T {
        let objType = T.self as! NSObject.Type
        let obj = objType.init() as! Persistable
        for key in T.kinveyPropertyMapping().keys {
            var value = json[key]
            if value is NSNull {
                value = nil
            }
            obj[key] = value
        }
        return obj as! T
    }
    
    func fromJson(jsonArray jsonArray: [JsonDictionary]) -> [T] {
        var results = [T]()
        for json in jsonArray {
            let obj = fromJson(json)
            results.append(obj)
        }
        return results
    }
    
    func toJson(array: [T]) -> [JsonDictionary] {
        var entities = [[String : AnyObject]]()
        let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        for obj in array {
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
    func fillObject(persistable: T) -> T {
        if persistable.kinveyObjectId == nil {
            persistable.kinveyObjectId = "\(ObjectIdTmpPrefix)\(NSUUID().UUIDString)"
        }
        return persistable
    }
    
    func fillJson(json: [String : AnyObject]) -> [String : AnyObject] {
        var json = json
        if let user = client.activeUser {
            let aclKey = T.aclKey ?? PersistableAclKey
            if var acl = json[aclKey] as? [String : AnyObject] where acl[Acl.CreatorKey] as? String == nil {
                acl[Acl.CreatorKey] = user.userId
            } else {
                json[aclKey] = [Acl.CreatorKey : user.userId]
            }
        }
        let kmdKey = T.kmdKey ?? PersistableMetadataKey
        if json[kmdKey] == nil {
            json[kmdKey] = [Metadata.EctKey : NSDate().toString()]
        }
        return json
    }
    
    func merge(persistableArray: [T], jsonArray: [JsonDictionary]) -> [JsonDictionary] {
        var results = [JsonDictionary]()
        if persistableArray.count == jsonArray.count && persistableArray.count > 0 {
            for i in 0...persistableArray.count - 1 {
                results.append(merge(persistableArray[i], json: jsonArray[i]))
            }
        }
        return results
    }
    
    func merge(persistable: T, json: JsonDictionary) -> JsonDictionary {
        var persistableJson = persistable._toJson()
        if T.kmdKey == nil {
            persistableJson[PersistableMetadataKey] = json[PersistableMetadataKey]
            if var kmd = persistableJson[PersistableMetadataKey] as? JsonDictionary {
                if let lmt = kmd[Metadata.LmtKey] as? String {
                    kmd[Metadata.LmtKey] = lmt
                }
                if let ect = kmd[Metadata.EctKey] as? String {
                    kmd[Metadata.EctKey] = ect
                }
                persistableJson[PersistableMetadataKey] = kmd
            }
        }
        if let acl = json[PersistableAclKey] where acl.count > 0 {
            let decorateAcl: (String) -> Void = { aclKey in
                persistableJson[PersistableAclKey] = acl
                if var acl = persistableJson[aclKey] as? JsonDictionary where acl.count > 0 {
                    if let readers = acl[Acl.ReadersKey] as? [String] {
                        acl[Acl.ReadersKey] = readers.map { ["stringValue" : $0] }
                    }
                    
                    if let writers = acl[Acl.WritersKey] as? [String] {
                        acl[Acl.WritersKey] = writers.map { ["stringValue" : $0] }
                    }
                    
                    persistableJson[aclKey] = acl
                }
            }
            decorateAcl(T.aclKey ?? PersistableAclKey)
        }
        for keyPair in persistableJson {
            if !EntitySchema.isTypeSupported(keyPair.1) {
                if let obj = keyPair.1 as? JsonObject {
                    var json: JsonDictionary? = nil
                    if let toJson = obj.toJson {
                        json = toJson()
                    } else {
                        json = obj._toJson()
                    }
                    let data = try! NSJSONSerialization.dataWithJSONObject(json!, options: [])
                    persistableJson[keyPair.0] = NSString(data: data, encoding: NSUTF8StringEncoding)!
                } else if let obj = keyPair.1 as? NSCoding {
                    let data = NSMutableData()
                    let coder = NSKeyedArchiver(forWritingWithMutableData: data)
                    obj.encodeWithCoder(coder)
                    coder.finishEncoding()
                    persistableJson[keyPair.0] = data.base64EncodedStringWithOptions([])
                }
            }
        }
        return persistableJson
    }
    
}
