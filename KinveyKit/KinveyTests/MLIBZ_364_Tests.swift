//
//  MLIBZ_364_Tests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-03.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class MLIBZ_364_Tests: XCTestCase {
    
    override func setUp() {
        KCSClient.sharedClient().initializeKinveyServiceForAppKey("kid_-k8AUP2hw", withAppSecret: "baf2a70a7fc1497ba00614528be622dd", usingOptions: nil)
    }

    func test() {
        weak var expectationCheckUsername = expectationWithDescription("CheckUsername")
        
        let username = "chicksabcs@gmail.com"
        KCSUser.checkUsername(username, withCompletionBlock: { (_username: String!, usernameAlreadyTaken: Bool, error: NSError!) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(_username)
            if (_username != nil) {
                XCTAssertEqual(username, _username)
            }
            
            expectationCheckUsername?.fulfill()
        })
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }

}
