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
    
    func testValidURL() {
        XCTAssertTrue(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?code=123")
        ))
    }
    
    func testValidURLDifferentURI() {
        XCTAssertFalse(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "facebook://?code=123")
        ))
    }
    
    func testValidURLMutipleParams() {
        XCTAssertTrue(KCSUser.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?type=kinvey_mic&code=123")
        ))
    }
    
    func testParseURLParams() {
        var params: NSDictionary?
        KCSUser2.isValidMICRedirectURI(
            "kinveyAuthDemo://",
            forURL: NSURL(string: "kinveyAuthDemo://?type=kinvey_mic&code=123"),
            params: &params
        )
        XCTAssertEqual(params!.count, 2)
        XCTAssertEqual(params!["code"] as String, "123")
        XCTAssertEqual(params!["type"] as String, "kinvey_mic")
    }
    
    func testAuthCodeApi() {
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
            XCTAssertNotNil(user)
            XCTAssertNotNil(user.userId)
            XCTAssertNotNil(user.username)
            XCTAssertNotNil(user.userAttributes)
            
            let socialIdentity = user.userAttributes["_socialIdentity"] as NSDictionary
            
            XCTAssertNotNil(socialIdentity)
            
            let kinveyAuth = socialIdentity["kinveyAuth"] as NSDictionary
            
            XCTAssertNotNil(kinveyAuth)
            XCTAssertNotNil(kinveyAuth["access_token"])
            XCTAssertNotNil(kinveyAuth["audience"])
            XCTAssertNotNil(kinveyAuth["client_token"])
            XCTAssertNotNil(kinveyAuth["refresh_token"])
            XCTAssertNotNil(kinveyAuth["id"])
            XCTAssertEqual(kinveyAuth["id"] as String, "mjs")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
}
