//
//  PerformanceTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class PerformanceTestCase: StoreTestCase {
    
    func testPerformanceFindNoDeltaSet1K() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            store = DataStore<Person>.collection(.sync)
            
            let n = 1000
            
            for _ in 1...n {
                save(newPerson)
            }
            
            weak var expectationPush = self.expectation(description: "Push")
            
            store.push(timeout: 300) { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(Int(count), n)
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectations(timeout: TimeInterval(Int16.max)) { error in
                expectationPush = nil
            }
            
            let query = Query(format: "\(Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator ==  %@", user.userId)
            
            self.measure {
                weak var expectationFind = self.expectation(description: "Find")
                
                self.store.find(query, options: Options(deltaSet: false)) {
                    switch $0 {
                    case .success(let results):
                        XCTAssertEqual(results.count, n)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
    }
    
    func testPerformanceFindNoDeltaSet10K() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            store = DataStore<Person>.collection(.sync)
            
            let n = 10000
            
            for _ in 1...n {
                save(newPerson)
            }
            
            weak var expectationPush = self.expectation(description: "Push")
            
            store.push(timeout: 1800) { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(Int(count), n)
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectations(timeout: TimeInterval(Int16.max)) { error in
                expectationPush = nil
            }
            
            let query = Query(format: "\(Person.aclProperty() ?? Person.EntityCodingKeys.acl.rawValue).creator ==  %@", user.userId)
            
            self.measure {
                weak var expectationFind = self.expectation(description: "Find")
                
                self.store.find(query, options: Options(deltaSet: false)) {
                    switch $0 {
                    case .success(let results):
                        XCTAssertEqual(results.count, n)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
    }
    
}
