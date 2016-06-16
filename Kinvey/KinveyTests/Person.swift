//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import ObjectMapper
import Realm
@testable import Kinvey

class Person: Entity {
    
    dynamic var personId: String?
    dynamic var name: String?
    dynamic var age: Int = 0
    
    required override init() {
        super.init()
    }
    
    init(personId: String? = nil, name: String) {
        self.personId = personId
        self.name = name
        super.init()
    }
    
    required init?(_ map: Map) {
        super.init()
    }
    
    required init(value: AnyObject, schema: RLMSchema) {
        fatalError("init(value:schema:) has not been implemented")
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        fatalError("init(realm:schema:) has not been implemented")
    }
    
    override class func kinveyCollectionName() -> String {
        return "Person"
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        personId <- map[PersistableIdKey]
        name <- map["name"]
        age <- map["age"]
        
    }
    
}
