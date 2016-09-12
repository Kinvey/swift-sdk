//
//  JsonObject.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public typealias JsonDictionary = [String : AnyObject]

/// Protocol used to serialize and deserialize JSON objects into objects.
@objc(KNVJsonObject)
public protocol JsonObject {
    
    /// Deserialize JSON object into object.
    optional func fromJson(json: JsonDictionary)
    
    /// Serialize object to JSON.
    optional func toJson() -> JsonDictionary

}

extension JsonObject {
    
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
    
    internal func _toJson() -> JsonDictionary {
        var json = JsonDictionary()
        let properties = ObjCRuntime.propertyNames(self.dynamicType)
        for property in properties {
            json[property] = self[property]
        }
        return json
    }
    
    internal func _fromJson(json: JsonDictionary) {
        for keyPair in json {
            self[keyPair.0] = keyPair.1
        }
    }
    
}

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    
    private func translateValue(value: AnyObject) -> AnyObject {
        if let query = value as? Query, let predicate = query.predicate, let value = try? MongoDBPredicateAdaptor.queryDictFromPredicate(predicate) {
            return value
        } else if let dictionary = value as? JsonDictionary {
            return dictionary.reduce(JsonDictionary(), combine: { (items, item) -> JsonDictionary in
                var items = items
                items[item.0] = translateValue(item.1)
                return items
            })
        } else if let array = value as? Array<AnyObject> {
            return array.map({ (item) -> AnyObject in
                return translateValue(item)
            })
        }
        return value
    }
    
    func toJson() -> JsonDictionary {
        var result = JsonDictionary()
        for item in self {
            result[item.0 as! String] = translateValue(item.1)
        }
        return result
    }
    
}
