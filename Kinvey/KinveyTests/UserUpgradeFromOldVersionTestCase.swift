//
//  UserUpgradeFromOldVersionTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-03-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import Kinvey

class UserTestCase: XCTestCase {
    
    func testUpgradeFromOldVersion() {
        let userDict: [String : Any] = [
            "_kmd" : [
                "ect" : "2017-03-17T20:32:48.583Z",
                "lmt" : "2017-03-17T20:32:48.583Z"
            ],
            "_id" : "58cc47f05380efd13729b72f",
            "username" : "bce8149b-5c0e-4e45-a3ac-7a05f0b2d87c",
            "_acl" : [
                "creator" : "58cc47f05380efd13729b72f"
            ]
        ]
        let appKey = "_kid_"
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(userDict, forKey: appKey)
        XCTAssertTrue(userDefaults.synchronize())
        
        XCTAssertNotNil(userDefaults.dictionary(forKey: appKey))
        
        weak var expectationInitialize = expectation(description: "Initialize")
        
        let client = Client()
        
        XCTAssertNil(client.activeUser)
        
        client.initialize(appKey: appKey, appSecret: "appSecret") { user, error in
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            
            if let user = user {
                XCTAssertEqual(user.userId, userDict["_id"] as? String)
                XCTAssertEqual(user.username, userDict["username"] as? String)
            }
            
            expectationInitialize?.fulfill()
        }
        
        waitForExpectations(timeout: KinveyTestCase.defaultTimeout) { (error) in
            expectationInitialize = nil
        }
        
        XCTAssertNotNil(client.activeUser)
        XCTAssertNil(userDefaults.dictionary(forKey: appKey))
    }
    
}
