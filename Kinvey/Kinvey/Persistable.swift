//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol Persistable: JsonObject {
    
    init(json: [String : AnyObject])
    
    func merge<T: Persistable>(object: T)
    
    static func kinveyPropertyMapping() -> [String : String]
    
}

extension Persistable {
    
    public var kinveyObjectId: String? {
        get {
            let propertyMap = self.dynamicType.kinveyPropertyMapping()
                .filter { keyValue in return keyValue.1 == Kinvey.PersistableIdKey }
                .map { keyValue in keyValue.0 }
            if let idKey = propertyMap.first,
                let persistable = self as? NSObject,
                let id = persistable.valueForKey(idKey) as? String
            {
                return id
            }
            return nil
        }
    }
    
}
