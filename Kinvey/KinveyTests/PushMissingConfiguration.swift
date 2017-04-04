//
//  PushMissingConfiguration.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-03-30.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import XCTest
import KIF
import Kinvey

class PushMissingConfigurationTestCase: KinveyTestCase {
    
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
    
}
