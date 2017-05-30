//
//  KinveyMacAppTests.swift
//  KinveyMacAppTests
//
//  Created by Victor Hugo on 2017-05-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
@testable import KinveyMacApp
import Kinvey

class KinveyMacAppTests: KinveyTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSignUp() {
        let username1 = UUID().uuidString
        let password1 = UUID().uuidString
        signUp(username: username1, password: password1)
        
        XCTAssertNotNil(client.activeUser)
        
        guard let user = client.activeUser else {
            return
        }
    }
    
}
