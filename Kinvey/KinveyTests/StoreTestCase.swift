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
            return "Person"
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
    var person:Person {
        get {
            let person = Person()
            person.name = "Victor"
            person.age = 29
            return person
        }
    }
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>(client: client)
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
    
    func testSubscript() {
        var person = self.person
        let age = 30
        person["age"] = age
        XCTAssertEqual(person.age, age)
    }
    
    func testCreate() {
        save()
    }
    
    func testRetrieve() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            XCTAssertNotEqual(personId, "")
            
            store.findById(personId) { (person, error) -> Void in
                self.assertThread()
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
    func testUpdate() {
        let person = save()
        
        weak var expectationUpdate = expectationWithDescription("Update")
        
        person.age = 30
        
        store.save(person) { (person, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.age)
                XCTAssertEqual(person.age, 30)
            }
            
            expectationUpdate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationUpdate = nil
        }
    }
    
    func testQuery() {
        save()
        
        weak var expectationQuery = expectationWithDescription("Query")
        
        XCTAssertNotNil(client.activeUser)
        
        store.find(Query(format: "age == %@ AND _acl.creator == %@", 29, client.activeUser!.acl!.creator)) { (persons, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(persons)
            XCTAssertNil(error)
            
            if let persons = persons {
                XCTAssertEqual(persons.count, 1)
            }
            
            expectationQuery?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationQuery = nil
        }
    }
    
    func testRemoveById() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationDelete = expectationWithDescription("Delete")
            
            store.removeById(personId) { (count, error) -> Void in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                if let count = count {
                    XCTAssertEqual(count, 0)
                }
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDelete = nil
            }
        }
    }
    
    func testRemoveByIds() {
        let person1 = save()
        let person2 = save()
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        if let personId1 = person1.personId, personId2 = person2.personId {
            weak var expectationDelete = expectationWithDescription("Delete")
            
            store.removeById([personId1, personId2]) { (count, error) -> Void in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                if let count = count {
                    XCTAssertEqual(count, 0)
                }
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDelete = nil
            }
        }
    }
    
    func testRemoveOneEntity() {
        let person = save()
        
        weak var expectationDelete = expectationWithDescription("Delete")
        
        try! store.remove(person) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            if let count = count {
                XCTAssertEqual(count, 0)
            }
            
            expectationDelete?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationDelete = nil
        }
    }
    
    func testRemoveMultipleEntity() {
        let person1 = save()
        let person2 = save()
        
        weak var expectationDelete = expectationWithDescription("Delete")
        
        store.remove([person1, person2]) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            if let count = count {
                XCTAssertEqual(count, 0)
            }
            
            expectationDelete?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationDelete = nil
        }
    }
    
    func testRemoveAll() {
        save()
        
        weak var expectationDelete = expectationWithDescription("Delete")
        
        store.removeAll() { (count, error) -> Void in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            if let count = count {
                XCTAssertGreaterThanOrEqual(count, 1)
            }
            
            expectationDelete?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationDelete = nil
        }
    }
    
}
