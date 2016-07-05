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
    
    var store: DataStore<Person>!
    var newPerson: Person {
        let person = Person()
        person.name = "Victor"
        person.age = 29
        return person
    }
    lazy var person: Person = self.newPerson
    
    func assertThread() {
        XCTAssertTrue(NSThread.isMainThread())
    }
    
    func save<T: Persistable where T: NSObject>(persistable: T, store: DataStore<T>) -> (originalPersistable: T, savedPersistable: T?) {
        weak var expectationCreate = expectationWithDescription("Create")
        
        var savedPersistable: T? = nil
        
        store.save(persistable) { (persistable, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(persistable)
            XCTAssertNil(error)
            
            if let persistable = persistable {
                XCTAssertNotNil(persistable.entityId)
            }
            
            savedPersistable = persistable
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return (originalPersistable: persistable, savedPersistable: savedPersistable)
    }
    
    func save(person: Person) -> Person {
        let age = person.age
        
        weak var expectationCreate = expectationWithDescription("Create")
        
        store.save(person) { (person, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.personId)
                XCTAssertNotEqual(person.personId, "")
                
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, age)
            }
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreate = nil
        }
        
        return person
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
