//
//  MICTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-30.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class MICTests: XCTestCase {
    
    override func setUp() {
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(
            "kid_WyYCSd34p",
            withAppSecret: "22a381bca79c407cb0efc6585aaed53e",
            usingOptions: nil
        )
    }
    
    func testAuthLoginPage() {
        let expectation = expectationWithDescription("login")
        
        KCSUser.loginWithMICRedirectURI(
            "kinveyAuthDemo://",
            authorizationGrantType: .AuthCodeAPI,
            options: [
                KCSUsername : "mjs",
                KCSPassword : "demo"
            ]
        ) { (user: KCSUser!, error: NSError!, userActionResult: KCSUserActionResult) -> Void in
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
}
