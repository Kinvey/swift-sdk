//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData
import ObjectMapper

@objc
public protocol KNVPersistable {
    
    static func kinveyCollectionName() -> String
    
}

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: Mappable, NSObjectProtocol {
    
    /// Provides the collection name to be matched with the backend.
    static func kinveyCollectionName() -> String
    
}

@objc(__KNVPersistable)
internal class __KNVPersistable: NSObject {
    
    class func idKey(type: Persistable.Type) -> String {
        return type.idKey
    }
    
    class func kmdKey(type: Persistable.Type) -> String? {
        return type.kmdKey
    }
    
    class func kinveyObjectId(persistable: Persistable) -> String? {
        return persistable.kinveyObjectId
    }
    
}

extension Persistable {
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [:]
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            guard let this = self as? NSObject else {
                return nil
            }
            return this.valueForKey(key)
        }
        set {
            guard let this = self as? NSObject else {
                return
            }
            this.setValue(newValue, forKey: key)
        }
    }
    
    /// Property that matches with the `_id` property.
    public static var idKey: String {
        get {
            let idKey = kinveyPropertyMapping()
                .filter { keyValuePair in keyValuePair.1 == PersistableIdKey }
                .reduce(PersistableIdKey) { (_, keyValuePair) in keyValuePair.0 }
            return idKey
        }
    }
    
    /// Property that matches with the `_acl` property.
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
    
    /// Property that matches with the `_kmd` property.
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
    
    /// Converts an array of persistable objects into a JSON array.
    public static func toJson<T : Persistable>(array: [T]) -> [JsonDictionary] {
        return Mapper().toJSONArray(array)
    }
    
    static func toJson<T : Persistable>(persistable obj: T) -> JsonDictionary {
        return Mapper().toJSON(obj)
    }
    
    static func fromJson<T: Persistable>(json: JsonDictionary) -> T {
        return Mapper<T>().map(json)!
    }
    
    static func fromJson<T: Persistable>(array: [JsonDictionary]) -> [T] {
        return Mapper<T>().mapArray(array)!
    }
    
    /// Converts the object into a `Dictionary<String, AnyObject>`.
    public func dictionaryWithValuesForKeys(keys: [String]) -> [String : AnyObject] {
        guard let this = self as? NSObject else {
            return [:]
        }
        return this.dictionaryWithValuesForKeys(keys)
    }
    
    /// Property value that matches with the `_id` property.
    public var kinveyObjectId: String? {
        get {
            guard let id = self[self.dynamicType.idKey] as? String else
            {
                return nil
            }
            return id
        }
        set {
            self[self.dynamicType.idKey] = newValue
        }
    }
    
    /// Property value that matches with the `_acl` property.
    public var kinveyAcl: Acl? {
        get {
            guard let aclKey = self.dynamicType.aclKey,
                let acl = self[aclKey] as? Acl else
            {
                return nil
            }
            return acl
        }
        set {
            guard let aclKey = self.dynamicType.aclKey else
            {
                return
            }
            self[aclKey] = newValue
        }
    }
    
    /// Serialize the persistable object to a JSON object.
    func _toJson() -> JsonDictionary {
        return Mapper().toJSON(self)
    }
    
    /// Deserialize a JSON object into the persistable object.
    func _fromJson(json: JsonDictionary) {
        for key in self.dynamicType.kinveyPropertyMapping().keys {
            self[key] = json[key]
        }
    }
    
    func merge(obj: Persistable) {
        _fromJson(obj._toJson())
    }
    
}
