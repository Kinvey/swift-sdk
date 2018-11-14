//
//  AutoStoreTests.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2018-11-13.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class AutoStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = try! DataStore<Person>.collection(type: .auto)
    }
    
    func testFind() {
        let id = "my-id"
        let name = "my-name"
        let query = Query(format: "entityId == %@", id)
        
        XCTContext.runActivity(named: "Find Local Empty") { (activity) in
            mockResponse(error: timeoutError)
            defer {
                setURLProtocol(nil)
            }
            
            let expectationFind = expectation(description: "Find")
            
            store.find(query, options: nil) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 0)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
        }
        
        XCTContext.runActivity(named: "Find Network") { (activity) in
            mockResponse(json: [
                [
                    "_id" : id,
                    "name" : name
                ]
            ])
            defer {
                setURLProtocol(nil)
            }
            
            let expectationFind = expectation(description: "Find")
            
            store.find(query, options: nil) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, name)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
        }
        
        XCTContext.runActivity(named: "Find Local") { (activity) in
            mockResponse(error: timeoutError)
            defer {
                setURLProtocol(nil)
            }
            
            let expectationFind = expectation(description: "Find")
            
            store.find(query, options: nil) {
                switch $0 {
                case .success(let persons):
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, name)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectationFind.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout)
        }
    }
    
}
