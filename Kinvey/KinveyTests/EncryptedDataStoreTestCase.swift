//
//  EncryptedDataStoreTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class EncryptedDataStoreTestCase: StoreTestCase {
    
    override func setUp() {
        encrypted = true
        
        super.setUp()
    }
    
    func testEncryptedDataStore() {
        signUp()
        
        store = DataStore<Person>.getInstance(.Network)
        
        save(newPerson)
    }
    
}
