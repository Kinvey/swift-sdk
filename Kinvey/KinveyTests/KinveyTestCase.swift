//
//  KinveyTests.swift
//  KinveyTests
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class KinveyTestCase: XCTestCase {
    
    var client: Client!
    
    var defaultTimeout: NSTimeInterval = 30
    
    override func setUp() {
        super.setUp()
        
        client = Kinvey.sharedClient().initialize(
            apiHostName: "https://v3yk1n-kcs.kinvey.com",
            appKey: "kid_Wy35WH6X9e",
            appSecret: "2498a81d1e9f4920b977b66ad62815e9"
        )
    }
    
    func signUp() {
        XCTAssertNil(client.activeUser)
        
        weak var expectationSignUp = expectationWithDescription("Sign Up")
        
        User.signup { user, error in
            expectationSignUp?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSignUp = nil
        }
        
        XCTAssertNotNil(client.activeUser)
    }
    
    override func tearDown() {
        if let user = client?.activeUser {
            user.logout()
        }
        
        super.tearDown()
    }
    
}
