//
//  GetOperationTest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest

class GetOperationTest: StoreTestCase {
    
    func testForceForceNetwork() {
        XCTAssertNotNil(person.personId)
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            store.findById(personId, readPolicy: .ForceNetwork) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
}
