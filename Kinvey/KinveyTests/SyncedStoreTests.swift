//
//  SyncedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class SyncedStoreTests: NetworkStoreTests {
    
    override func setUp() {
        super.setUp()
        
        store = DataStore<Person>.getInstance(.Sync)
    }
    
    func testPurge() {
        save()
        
        weak var expectationPurge = expectationWithDescription("Purge")
        
        let query = Query(format: "_acl.creatorId == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            expectationPurge?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testSync() {
        save()
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertGreaterThanOrEqual(Int(count), 1)
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPush = nil
        }
    }
    
    func testPush() {
        save()
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.push() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertGreaterThanOrEqual(Int(count), 1)
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPush = nil
        }
    }
    
    func testPull() {
        save()
        
        weak var expectationPull = expectationWithDescription("Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertGreaterThanOrEqual(results.count, 1)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPull = nil
        }
    }
    
}
