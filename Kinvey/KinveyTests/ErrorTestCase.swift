//
//  ErrorTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class ErrorTestCase: KinveyTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testObjectIDMissing() {
        XCTAssertEqual("\(Error.ObjectIdMissing)", "Object ID is required and is missing")
    }
    
    func testInvalidResponse() {
        XCTAssertEqual("\(Error.InvalidResponse(httpResponse: nil, data: nil))", "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual("\(Error.Unauthorized(httpResponse: nil, data: nil, error: "Error", description: "Description"))", "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual("\(Error.NoActiveUser)", "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual("\(Error.RequestCancelled)", "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual("\(Error.InvalidDataStoreType)", "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual("\(Error.UserWithoutEmailOrUsername)", "User has no email or username")
    }
    
    func testInvalidResponseHttpResponseData() {
        class MockURLProtocol: NSURLProtocol {
            
            override class func canInitWithRequest(request: NSURLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
                return request
            }
            
            override func startLoading() {
                let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 401, HTTPVersion: "1.1", headerFields: nil)!
                client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                client?.URLProtocol(self, didLoadData: "Unauthorized".dataUsingEncoding(NSUTF8StringEncoding)!)
                client?.URLProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret")
        
        setURLProtocol(MockURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUser = expectationWithDescription("User")
        
        User.signup(username: "test", password: "test") { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .InvalidResponse(let httpResponse, let data):
                    XCTAssertNotNil(httpResponse)
                    if let httpResponse = httpResponse {
                        XCTAssertEqual(httpResponse.statusCode, 401)
                    }
                    
                    XCTAssertNotNil(data)
                    if let data = data, let responseStringBody = String(data: data, encoding: NSUTF8StringEncoding) {
                        XCTAssertEqual(responseStringBody, "Unauthorized")
                    }
                default:
                    XCTFail()
                }
                
                XCTAssertNotNil(error.httpResponse)
                if let httpResponse = error.httpResponse {
                    XCTAssertEqual(httpResponse.statusCode, 401)
                }
            }
            
            expectationUser?.fulfill()
        }
        
        waitForExpectationsWithTimeout(30) { error in
            expectationUser = nil
        }
    }
    
}
