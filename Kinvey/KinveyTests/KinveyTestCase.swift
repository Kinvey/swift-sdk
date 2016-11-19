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
    static let appInitializeProduction = AppInitialize(appKey: MockKinveyBackend.kid, appSecret: "appSecret")
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
    
    class SignUpMockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
            return request
        }
        
        override func startLoading() {
            let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "1.1", headerFields: [ "Content-Type" : "application/json; charset=utf-8" ])!
            client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            
            var resquestBody: [String : AnyObject]? = nil
            if let data = request.HTTPBody {
                resquestBody = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
            } else if let httpBodyStream = request.HTTPBodyStream {
                httpBodyStream.open()
                defer {
                    httpBodyStream.close()
                }
                resquestBody = try! NSJSONSerialization.JSONObjectWithStream(httpBodyStream, options: []) as? [String : AnyObject]
            }
            
            var responseBody = [
                "_id" : NSUUID().UUIDString,
                "username" : (resquestBody?["username"] as? String) ?? NSUUID().UUIDString,
                "_kmd" : [
                    "lmt" : "2016-10-19T21:06:17.367Z",
                    "ect" : "2016-10-19T21:06:17.367Z",
                    "authtoken" : "my-auth-token"
                ],
                "_acl" : [
                    "creator" : "masterKey-creator-id"
                ]
            ] as [String : AnyObject]
            if let resquestBody = resquestBody {
                responseBody += resquestBody
            }
            let data = try! NSJSONSerialization.dataWithJSONObject(responseBody, options: [])
            client?.URLProtocol(self, didLoadData: data)
            
            client?.URLProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    func signUp<UserType: User>(username username: String? = nil, password: String? = nil, user: UserType? = nil, mustHaveAValidUserInTheEnd: Bool = true, completionHandler: ((UserType?, ErrorType?) -> Void)? = nil) {
        if let user = client.activeUser {
            user.logout()
        }
        
        setURLProtocol(MockKinveyBackend.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSignUp = expectationWithDescription("Sign Up")
        
        let handler: (UserType?, ErrorType?) -> Void = { user, error in
            if let completionHandler = completionHandler {
                completionHandler(user, error)
            } else {
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertNil(error)
                XCTAssertNotNil(user)
            }
            
            expectationSignUp?.fulfill()
        }
        
        if let username = username {
            User.signup(username: username, user: user, completionHandler: handler)
        } else {
            User.signup(user: user, completionHandler: handler)
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
            setURLProtocol(MockKinveyBackend.self)
            defer {
                setURLProtocol(nil)
            }
            
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
