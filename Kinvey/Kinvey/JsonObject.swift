//
//  JsonObject.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public typealias JsonDictionary = [String : Any]

func +=(lhs: inout JsonDictionary, rhs: JsonDictionary) {
    for (key, value) in rhs {
        lhs[key] = value
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    
    fileprivate func translateValue(_ value: Any) -> Any {
        if let query = value as? Query, let predicate = query.predicate, let value = predicate.json {
            return value
        } else if let dictionary = value as? JsonDictionary {
            var translated = JsonDictionary()
            for (key, value) in dictionary {
                translated[key] = translateValue(value)
            }
            return translated
        } else if let array = value as? Array<Any> {
            return array.map({ (item) -> Any in
                return translateValue(item)
            })
        }
        return value
    }
    
    func toJson() -> JsonDictionary {
        var result = JsonDictionary()
        for (key, value) in self {
            result[key as! String] = translateValue(value)
        }
        return result
    }
    
}
