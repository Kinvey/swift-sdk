//
//  PushTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2016-12-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
#if canImport(KIF)
    import KIF
#endif
@testable import Kinvey
import Foundation

class PushTestCase: KinveyTestCase {
    
    func testHexStringConvertion() {
        XCTAssertEqual("Hello World!".data(using: .utf8)?.hexString(), "48656c6c6f20576f726c6421")
    }
    
#if os(iOS)
    func testRegisterForPush() {
        signUp()
        
        do {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectaionRegister = expectation(description: "Register")
            
            Kinvey.sharedClient.push.registerForNotifications { result, error in
                XCTAssertTrue(result)
                XCTAssertNil(error)
                
                XCTAssertNotNil(Kinvey.sharedClient.push.deviceToken)
                
                expectaionRegister?.fulfill()
            }

            #if (arch(i386) || arch(x86_64)) && os(iOS)
            tester().acknowledgeSystemAlert()
            
            DispatchQueue.main.async {
                let app = UIApplication.shared
                let data = UUID().uuidString.data(using: .utf8)!
                app.delegate!.application!(app, didRegisterForRemoteNotificationsWithDeviceToken: data)
            }
            #endif
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectaionRegister = nil
            }
        }
        
        do {
            if useMockData {
                mockResponse(statusCode: 204, data: Data())
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectaionUnRegister = expectation(description: "UnRegister")
            
            Kinvey.sharedClient.push.unRegisterDeviceToken { result, error in
                XCTAssertTrue(result)
                XCTAssertNil(error)
                
                expectaionUnRegister?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectaionUnRegister = nil
            }
        }
    }
    
    func testUnregisterDeviceToken() {
        let client = Client(appKey: "_appKey_", appSecret: "_appSecret_")
        
        weak var expectaionUnRegister = expectation(description: "UnRegister")
        
        client.push.unRegisterDeviceToken { (success, error) in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Device token not found")
            
            expectaionUnRegister?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectaionUnRegister = nil
        }
    }
    
    func testBadgeNumber() {
        UIApplication.shared.applicationIconBadgeNumber = 1
        
        XCTAssertEqual(Kinvey.sharedClient.push.badgeNumber, 1)
        
        Kinvey.sharedClient.push.badgeNumber = 2
        
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 2)
        
        Kinvey.sharedClient.push.resetBadgeNumber()
        
        XCTAssertEqual(Kinvey.sharedClient.push.badgeNumber, 0)
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 0)
    }
#endif
    
}
