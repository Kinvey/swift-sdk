//
//  MacOSOnlyTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-08-30.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class MacOSOnlyTestCase: KinveyTestCase {
    
    func testCachePath() {
        let dataStore = try! DataStore<Person>.collection(.sync)
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        dataStore.save(person, options: nil) { (result: Result<Person, Swift.Error>) in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            expectationSave = nil
        }
        
        let realmCache = dataStore.cache?.cache as? RealmCache<Person>
        XCTAssertEqual(realmCache?.configuration.fileURL?.path, "\(Kinvey.cacheBasePath)/_kid_/kinvey.realm")
    }
    
}
