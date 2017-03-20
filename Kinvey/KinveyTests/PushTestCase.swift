//
//  PushTestCase.swift
//  Kinvey
//
//  Created by Victor Hugo on 2016-12-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import KIF
@testable import Kinvey

class PushTestCase: KinveyTestCase {
    
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
    
    func testMissingConfigurationError() {
        signUp()
        
        do {
            if useMockData {
                mockResponse(statusCode: 403, json: [
                    "error" : "MissingConfiguration",
                    "description" : "This feature is not properly configured for this app backend. Please configure it through the console first, or contact support for more information.",
                    "debug" : "Push notifications for iOS are not properly configured for this app backend. Please enable push notifications through the console first."
                ])
            }
            defer {
                if useMockData {
                    setURLProtocol(nil)
                }
            }
            
            weak var expectaionRegister = expectation(description: "Register")
            
            Kinvey.sharedClient.push.registerForNotifications { result, error in
                XCTAssertFalse(result)
                XCTAssertNotNil(error)
                
                if let error = error {
                    XCTAssertTrue(error is Kinvey.Error)
                    if let error = error as? Kinvey.Error {
                        switch error {
                        case .missingConfiguration(let httpResponse, _, let debug, let description):
                            XCTAssertEqual(httpResponse?.statusCode, 403)
                            XCTAssertEqual(debug, "Push notifications for iOS are not properly configured for this app backend. Please enable push notifications through the console first.")
                            XCTAssertEqual(description, "This feature is not properly configured for this app backend. Please configure it through the console first, or contact support for more information.")
                        default:
                            XCTFail()
                        }
                    }
                }
                
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
    
}
