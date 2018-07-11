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
        
        store = try! DataStore<Person>.collection(.network)
    }
    
    override func tearDown() {
        super.tearDown()
        store.ttl = nil
    }
    
    override func save() -> Person {
        let person = self.person
        
        weak var expectationSave = expectation(description: "Save")

        store.save(person, options: try! Options(writePolicy: .forceLocal)) {
            switch $0 {
            case .success(let person):
                XCTAssertEqual(person, self.person)
                XCTAssertNotNil(person.personId)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
        
        return person
    }
    
    func testForceLocal() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let person):
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
    func testForceLocalExpiredTTL() {
        store.ttl = 1.seconds
        
        let person = save()
        
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, options: try! Options(readPolicy: .forceLocal)) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
}
