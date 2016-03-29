//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData

@objc(KNVPersistable)
public protocol Persistable: JsonObject, NSObjectProtocol {
    
    static func kinveyCollectionName() -> String
    static func kinveyPropertyMapping() -> [String : String]
    
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
    
    static func toJson(persistable obj: Persistable) -> JsonDictionary {
        var json: [String : AnyObject] = [:]
        let propertyMap = self.kinveyPropertyMapping()
        for keyValuePair in propertyMap {
            if let value = obj[keyValuePair.0] {
                json[keyValuePair.1] = value
            }
        }
        return json
    }
    
    static func fromJson(json: JsonDictionary) -> Persistable {
        let type = self as! NSObject.Type
        let obj = type.init()
        let persistable = obj as! Persistable
        let persistableType = obj.dynamicType as! Persistable.Type
        let propertyMap = persistableType.kinveyPropertyMapping()
        for keyValuePair in propertyMap {
            var value = json[keyValuePair.1]
            if let entitySchema = EntitySchema.entitySchema(type),
                let destinationType = entitySchema.properties[keyValuePair.0]
            {
                if let valueNonNull = value where !valueNonNull.isKindOfClass(destinationType.1.0),
                    let valueTransformer = ValueTransformer.valueTransformer(fromClass: valueNonNull.dynamicType, toClass: destinationType.1.0)
                {
                    if let destinationType = destinationType.1.0 as? NSDate.Type,
                        let transformedValue = valueTransformer.transformValue(value, destinationType: destinationType)
                    {
                        value = transformedValue
                    } else {
                        value = nil
                    }
                }
                obj.setValue(value, forKey: keyValuePair.0)
            }
        }
        return persistable
    }
    
    static func fromJson(array: [JsonDictionary]) -> [Persistable] {
        var results = [Persistable]()
        for item in array {
            results.append(fromJson(item))
        }
        return results
    }
    
    //MARK: NSObject
    
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
    
    public func dictionaryWithValuesForKeys(keys: [String]) -> [String : AnyObject] {
        guard let this = self as? NSObject else {
            return [:]
        }
        return this.dictionaryWithValuesForKeys(keys)
    }
    
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
    
    public func toJson() -> JsonDictionary {
        let keys = self.dynamicType.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        return dictionaryWithValuesForKeys(keys)
    }
    
    public func fromJson(json: JsonDictionary) {
        for key in self.dynamicType.kinveyPropertyMapping().keys {
            self[key] = json[key]
        }
    }
    
    func merge(obj: Persistable) {
        fromJson(obj.toJson())
    }
    
}
