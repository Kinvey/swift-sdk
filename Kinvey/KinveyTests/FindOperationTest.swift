//
//  GetOperationTest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class FindOperationTest: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        
        store = DataStore<Person>.getInstance(.Network)
    }
    
    override func tearDown() {
        super.tearDown()
        store.ttl = nil
    }
    
    override func save() -> Person {
        let person = self.person
        
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person, writePolicy: .ForceLocal) { (person, error) -> Void in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertEqual(person, self.person)
                XCTAssertNotNil(person.personId)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
        
        return person
    }
    
    func testForceLocal() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .ForceLocal) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
    func testForceLocalExpiredTTL() {
        store.ttl = 1.seconds
        
        let person = save()
        
        NSThread.sleepForTimeInterval(1)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .ForceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
}
