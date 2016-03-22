//
//  StoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class StoreTestCase: KinveyTestCase {
    
    class Person: NSObject, Persistable {
        
        dynamic var personId: String?
        dynamic var name: String?
        dynamic var age: Int = 0
        
        static func kinveyCollectionName() -> String {
            return NSStringFromClass(self)
        }
        
        static func kinveyPropertyMapping() -> [String : String] {
            return [
                "personId" : Kinvey.PersistableIdKey,
                "name" : "name",
                "age" : "age"
            ]
        }
        
    }
    
    var store: DataStore<Person>!
    lazy var person:Person = {
        let person = Person()
        person.name = "Victor"
        person.age = 29
        return person
    }()
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.getInstance(client: client)
    }
    
    func assertThread() {
        XCTAssertTrue(NSThread.isMainThread())
    }
    
    func save() -> Person {
        let person = self.person
        
        weak var expectationCreate = expectationWithDescription("Create")
        
        store.save(person) { (person, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 29)
            }
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return person
    }
    
}
