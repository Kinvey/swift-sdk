//
//  Bus.swift
//  BuSber
//
//  Created by Vinay Gahlawat on 5/3/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class Bus : NSObject, Persistable
{
    dynamic var name: String?
    dynamic var location: Array<Double>?
    
    static func kinveyCollectionName() -> String {
        return "Bus"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return ["_id": PersistableIdKey, "name": "name", "location": "location"]
    }
}
