//
//  CachedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class CachedStoreTests: NetworkStoreTests {
    
    override func setUp() {
        super.setUp()
        
        store = CachedStore<Person>(expiration: (1, .Day), client: client)
    }
    
}
