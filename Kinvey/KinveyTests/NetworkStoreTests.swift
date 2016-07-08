//
//  NetworkStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class NetworkStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        signUp()
        
        store = DataStore<Person>.getInstance()
    }
    
    override func assertThread() {
        XCTAssertTrue(NSThread.isMainThread())
    }
    
    func testSaveEvent() {
        let store = DataStore<Event>.getInstance(.Network)
        
        let event = Event()
        event.name = "Friday Party!"
        event.date = NSDate(timeIntervalSince1970: 1468001397) // Fri, 08 Jul 2016 18:09:57 GMT
        event.location = "The closest pub!"
        
        event.acl?.globalRead.value = true
        event.acl?.globalWrite.value = true
        
        weak var expectationCreate = expectationWithDescription("Create")
        
        store.save(event) { event, error in
            XCTAssertNotNil(event)
            XCTAssertNil(error)
            
            expectationCreate?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationCreate = nil
        }
    }
    
}
