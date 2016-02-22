//
//  JsonObject.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public typealias JsonDictionary = [String : AnyObject]

@objc(KNVJsonObject)
public protocol JsonObject {
    
    optional func fromJson(json: JsonDictionary)
    optional func toJson() -> JsonDictionary

}
