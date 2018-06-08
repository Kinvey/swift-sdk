//
//  LongData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey
import ObjectMapper

class LongData: Entity {
    
    @objc
    dynamic var id: String?
    
    @objc
    dynamic var seq: Int = 0
    
    @objc
    dynamic var first: String?
    
    @objc
    dynamic var last: String?
    
    @objc
    dynamic var age: Int = 0
    
    @objc
    dynamic var street: String?
    
    @objc
    dynamic var city: String?
    
    @objc
    dynamic var state: String?
    
    @objc
    dynamic var zip: Int = 0
    
    @objc
    dynamic var dollar: String?
    
    @objc
    dynamic var pick: String?
    
    @objc
    dynamic var paragraph: String?
    
    override class func collectionName() -> String {
        return "longdata"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        id <- map[Entity.CodingKeys.entityId]
        seq <- map["seq"]
        first <- map["first"]
        last <- map["last"]
        age <- map["age"]
        street <- map["street"]
        city <- map["city"]
        state <- map["state"]
        zip <- map["zip"]
        dollar <- map["dollar"]
        pick <- map["pick"]
        paragraph <- map["paragraph"]
    }
    
}
