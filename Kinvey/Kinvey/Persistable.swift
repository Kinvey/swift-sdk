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

public protocol Persistable: JsonObject {
    
    static func kinveyCollectionName() -> String
    static func kinveyPropertyMapping() -> [String : String]
    
}

extension Persistable {
    
    public var kinveyObjectId: String? {
        get {
            let propertyMap = self.dynamicType.kinveyPropertyMapping()
                .filter { keyValue in return keyValue.1 == Kinvey.PersistableIdKey }
                .map { keyValue in keyValue.0 }
            if let idKey = propertyMap.first,
                let persistable = self as? AnyObject,
                let id = persistable.valueForKey(idKey) as? String
            {
                return id
            }
            return nil
        }
    }
    
    subscript(key: String) -> AnyObject? {
        get {
            if let obj = self as? NSObject {
                return obj.valueForKey(key)
            }
            return nil
        }
        set {
            if let obj = self as? NSObject {
                obj.setValue(newValue, forKey: key)
            }
        }
    }
    
    public func toJson() -> [String : AnyObject] {
        var json: [String : AnyObject] = [:]
        if let obj = self as? NSObject {
            let propertyMap = self.dynamicType.kinveyPropertyMapping()
            for keyValuePair in propertyMap {
                if let value = obj.valueForKey(keyValuePair.0) {
                    if keyValuePair.1 == Kinvey.PersistableIdKey {
                        if value as? String != "" {
                            json[keyValuePair.1] = value
                        }
                    } else {
                        json[keyValuePair.1] = value
                    }
                }
            }
        }
        return json
    }
    
    public func loadFromJson(json: [String : AnyObject]) {
        if let obj = self as? NSObject {
            let propertyMap = self.dynamicType.kinveyPropertyMapping()
            for keyValuePair in propertyMap {
                if let value = json[keyValuePair.1] {
                    obj.setValue(value, forKey: keyValuePair.0)
                }
            }
        }
    }
    
}
