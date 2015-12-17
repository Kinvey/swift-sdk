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
        
        store = NetworkStore<Person>(client: client)
    }
    
    override func assertThread() {
        XCTAssertTrue(NSThread.isMainThread())
    }
    
}
