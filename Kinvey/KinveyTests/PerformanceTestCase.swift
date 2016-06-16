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
            store = DataStore<Person>.getInstance(.Sync)
            
            let n = 1000
            
            for _ in 1...n {
                save(newPerson)
            }
            
            weak var expectationPush = self.expectationWithDescription("Push")
            
            store.push(timeout: 300) { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(Int(count), n)
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(NSTimeInterval(Int16.max)) { error in
                expectationPush = nil
            }
            
            let query = Query(format: "\(Person.kinveyAclPropertyName() ?? PersistableAclKey).creator ==  %@", user.userId)
            
            self.measureBlock {
                weak var expectationFind = self.expectationWithDescription("Find")
                
                self.store.find(query, deltaSet: false) { results, error in
                    XCTAssertNotNil(results)
                    XCTAssertNil(error)
                    
                    if let results = results {
                        XCTAssertEqual(results.count, n)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectationsWithTimeout(self.defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
    }
    
    func testPerformanceFindNoDeltaSet10K() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        
        if let user = client.activeUser {
            store = DataStore<Person>.getInstance(.Sync)
            
            let n = 10000
            
            for _ in 1...n {
                save(newPerson)
            }
            
            weak var expectationPush = self.expectationWithDescription("Push")
            
            store.push(timeout: 1800) { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(Int(count), n)
                }
                
                expectationPush?.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(NSTimeInterval(Int16.max)) { error in
                expectationPush = nil
            }
            
            let query = Query(format: "\(Person.kinveyAclPropertyName() ?? PersistableAclKey).creator ==  %@", user.userId)
            
            self.measureBlock {
                weak var expectationFind = self.expectationWithDescription("Find")
                
                self.store.find(query, deltaSet: false) { results, error in
                    XCTAssertNotNil(results)
                    XCTAssertNil(error)
                    
                    if let results = results {
                        XCTAssertEqual(results.count, n)
                    }
                    
                    expectationFind?.fulfill()
                }
                
                self.waitForExpectationsWithTimeout(self.defaultTimeout) { error in
                    expectationFind = nil
                }
            }
        }
    }
    
}
