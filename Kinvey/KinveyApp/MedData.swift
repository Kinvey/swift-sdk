//
//  MedData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class MedData: Entity {
    
    dynamic var entityId: String?
    dynamic var seq: Int = 0
    dynamic var first: String?
    dynamic var last: String?
    dynamic var age: Int = 0
    dynamic var street: String?
    dynamic var city: String?
    dynamic var state: String?
    dynamic var zip: Int = 0
    dynamic var dollar: String?
    dynamic var pick: String?
    
    override class func kinveyCollectionName() -> String {
        return "meddata"
    }
    
    override func kinveyPropertyMapping(map: Map) {
        super.kinveyPropertyMapping(map)
        
        entityId <- ("entityId", map[PersistableIdKey])
    }
    
}
