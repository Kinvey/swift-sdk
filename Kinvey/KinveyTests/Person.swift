//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@testable import Kinvey

class Person: NSObject, Persistable {
    
    dynamic var personId: String?
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var acl: Acl? = nil
    
    override init() {
    }
    
    init(personId: String? = nil, name: String) {
        self.personId = personId
        self.name = name
    }
    
    static func kinveyCollectionName() -> String {
        return "Person"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "personId" : Kinvey.PersistableIdKey,
            "acl" : Kinvey.PersistableAclKey,
            "name" : "name",
            "age" : "age"
        ]
    }
    
}
