//
//  SyncedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class SyncedStoreTests: CachedStoreTests {
    
    override func setUp() {
        super.setUp()
        
        store = SyncedStore<Person>(client: client)
    }
    
}
