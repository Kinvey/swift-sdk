//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit
import CoreData

@objc(KNVPersistable)
public protocol Persistable: JsonObject, NSObjectProtocol {
    
    static func kinveyCollectionName() -> String
    static func kinveyPropertyMapping() -> [String : String]
    
}

extension Persistable where Self: NSObject {
    
    public var kinveyObjectId: String? {
        get {
            if let id = valueForKey(self.dynamicType.idKey) as? String
            {
                return id
            }
            return nil
        }
        set {
            setValue(newValue, forKey: self.dynamicType.idKey)
        }
    }
    
    public var kinveyAcl: Acl? {
        get {
            if let aclKey = self.dynamicType.aclKey,
                let acl = valueForKey(aclKey) as? Acl
            {
                return acl
            }
            return nil
        }
        set {
            if let aclKey = self.dynamicType.aclKey {
                setValue(newValue, forKey: aclKey)
            }
        }
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            return valueForKey(key)
        }
        set {
            setValue(newValue, forKey: key)
        }
    }
    
    public func toJson() -> JsonDictionary {
        let keys = self.dynamicType.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        return dictionaryWithValuesForKeys(keys)
    }
    
    public func fromJson(json: JsonDictionary) {
        for key in self.dynamicType.kinveyPropertyMapping().keys {
            setValue(json[key], forKey: key)
        }
    }
    
    func merge(obj: Persistable) {
        fromJson(obj.toJson!())
    }
    
}

extension Persistable {
    
    public static var idKey: String {
        get {
            let idKey = kinveyPropertyMapping()
                .filter { keyValuePair in keyValuePair.1 == PersistableIdKey }
                .reduce(PersistableIdKey) { (_, keyValuePair) in keyValuePair.0 }
            return idKey
        }
    }
    
    public static var aclKey: String? {
        get {
            let filtered = kinveyPropertyMapping()
                .filter { keyValuePair in keyValuePair.1 == PersistableAclKey }
            if filtered.count > 0 {
                let idKey = filtered.reduce(PersistableAclKey) { (_, keyValuePair) in keyValuePair.0 }
                return idKey
            }
            return nil
        }
    }
    
    public static var kmdKey: String? {
        get {
            let filtered = kinveyPropertyMapping()
                .filter { keyValuePair in keyValuePair.1 == PersistableMetadataKey }
            if filtered.count > 0 {
                let idKey = filtered.reduce(PersistableMetadataKey) { (_, keyValuePair) in keyValuePair.0 }
                return idKey
            }
            return nil
        }
    }
    
    public static func toJson(array: [Persistable]) -> [JsonDictionary] {
        var jsonArray: [[String : AnyObject]] = []
        for item in array {
            jsonArray.append(item.toJson!())
        }
        return jsonArray
    }
    
    static func toJson<T: Persistable where T: NSObject>(persistable obj: T) -> JsonDictionary {
        var json: [String : AnyObject] = [:]
        let propertyMap = T.kinveyPropertyMapping()
        for keyValuePair in propertyMap {
            if let value = obj.valueForKey(keyValuePair.0) {
                json[keyValuePair.1] = value
            }
        }
        return json
    }
    
    static func fromJson<T: Persistable where T: NSObject>(json: JsonDictionary) -> T {
        let obj = T.self.init()
        let propertyMap = T.self.kinveyPropertyMapping()
        for keyValuePair in propertyMap {
            if let value = json[keyValuePair.1] {
                obj.setValue(value, forKey: keyValuePair.0)
            }
        }
        return obj
    }
    
    static func fromJson<T: Persistable where T: NSObject>(array: [JsonDictionary]) -> [T] {
        var results: [T] = []
        for item in array {
            results.append(fromJson(item))
        }
        return results
    }
    
}
