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
