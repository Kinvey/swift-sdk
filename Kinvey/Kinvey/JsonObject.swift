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
