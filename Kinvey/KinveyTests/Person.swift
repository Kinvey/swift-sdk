//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@testable import Kinvey

class Person: Entity {
    
    dynamic var personId: String?
    dynamic var name: String?
    dynamic var age: Int = 0
    
    override class func collectionName() -> String {
        return "Person"
    }
    
    override func propertyMapping(map: Map) {
        super.propertyMapping(map)
        
        personId <- ("personId", map[PersistableIdKey])
        name <- map["name"]
        age <- map["age"]
    }
    
}
