//
//  KinveyTests.swift
//  KinveyTests
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

extension XCTestCase {
    
    func waitValueForObject<V: Equatable>(obj: NSObject, keyPath: String, expectedValue: V?, timeout: NSTimeInterval = 60) -> Bool {
        let date = NSDate()
        let loop = NSRunLoop.currentRunLoop()
        var result = false
        repeat {
            let currentValue = obj.valueForKey(keyPath)
            if let currentValue = currentValue as? V {
                result = currentValue == expectedValue
            } else if currentValue == nil && expectedValue == nil {
                result = true
            }
            if !result {
                loop.runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
            }
        } while !result && -date.timeIntervalSinceNow > timeout
        return result
    }
    
}

class KinveyTestCase: XCTestCase {
    
    var client: Client!
    var encrypted = false
    
    static let defaultTimeout = NSTimeInterval(Int8.max)
    lazy var defaultTimeout: NSTimeInterval = {
        KinveyTestCase.defaultTimeout
    }()
    
    typealias AppInitialize = (appKey: String, appSecret: String)
    static let appInitializeDevelopment = AppInitialize(appKey: "kid_Wy35WH6X9e", appSecret: "d85f81cad5a649baaa6fdcd99a108ab1")
    static let appInitializeProduction = AppInitialize(appKey: "kid_WyWKm0pPM-", appSecret: "081bc930604446de9153292f05c1b8e9")
    static let appInitialize = appInitializeProduction
    
    func initializeDevelopment() {
        client = Kinvey.sharedClient.initialize(
            appKey: KinveyTestCase.appInitializeDevelopment.appKey,
            appSecret: KinveyTestCase.appInitializeDevelopment.appSecret,
            apiHostName: NSURL(string: "https://v3yk1n-kcs.kinvey.com")!,
            encrypted: encrypted
        )
    }
    
    func initializeProduction() {
        client = Kinvey.sharedClient.initialize(
            appKey: KinveyTestCase.appInitializeProduction.appKey,
            appSecret: KinveyTestCase.appInitializeProduction.appSecret,
            encrypted: encrypted
        )
    }
    
    override func setUp() {
        super.setUp()
        
        if KinveyTestCase.appInitialize == KinveyTestCase.appInitializeDevelopment {
            initializeDevelopment()
        } else {
            initializeProduction()
        }
        
        XCTAssertNotNil(client.isInitialized())
        
        if let activeUser = client.activeUser {
            activeUser.logout()
        }
    }
    
    func signUp(username username: String? = nil, password: String? = nil, mustHaveAValidUserInTheEnd: Bool = true, completionHandler: ((User?, ErrorType?) -> Void)? = nil) {
        if let user = client.activeUser {
            user.logout()
        }
        
        weak var expectationSignUp = expectationWithDescription("Sign Up")
        
        User.signup(username: username, password: password) { user, error in
            if let completionHandler = completionHandler {
                completionHandler(user, error)
            } else {
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
            }
            
            expectationSignUp?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSignUp = nil
        }
        
        if mustHaveAValidUserInTheEnd {
            XCTAssertNotNil(client.activeUser)
        }
    }
    
    func signUp(username username: String, password: String) {
        if let user = client.activeUser {
            user.logout()
        }
        
        weak var expectationSignUp = expectationWithDescription("Sign Up")
        
        User.signup(username: username, password: password) { user, error in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            
            expectationSignUp?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSignUp = nil
        }
        
        XCTAssertNotNil(client.activeUser)
    }
    
    override func tearDown() {
        setURLProtocol(nil)
        
        if let user = client?.activeUser {
            weak var expectationDestroyUser = expectationWithDescription("Destroy User")
            
            user.destroy { (error) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                
                expectationDestroyUser?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationDestroyUser = nil
            }
            
            XCTAssertNil(client.activeUser)
        }
        
        super.tearDown()
    }
    
    func setURLProtocol(type: NSURLProtocol.Type?) {
        if let type = type {
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            sessionConfiguration.protocolClasses = [type]
            client.urlSession = NSURLSession(configuration: sessionConfiguration)
            XCTAssertEqual(client.urlSession.configuration.protocolClasses!.count, 1)
        } else {
            client?.urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
    }
    
}
