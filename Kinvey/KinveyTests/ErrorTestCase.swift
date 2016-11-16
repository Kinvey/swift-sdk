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
        XCTAssertEqual(Kinvey.Error.objectIdMissing.localizedDescription, "Object ID is required and is missing")
    }
    
    func testInvalidResponse() {
        XCTAssertEqual(Kinvey.Error.invalidResponse(httpResponse: nil, data: nil).localizedDescription, "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual(Kinvey.Error.unauthorized(httpResponse: nil, data: nil, error: "Error", description: "Description").localizedDescription, "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual(Kinvey.Error.noActiveUser.localizedDescription, "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual(Kinvey.Error.requestCancelled.localizedDescription, "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual(Kinvey.Error.invalidDataStoreType.localizedDescription, "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual(Kinvey.Error.userWithoutEmailOrUsername.localizedDescription, "User has no email or username")
    }
    
    func testInvalidResponseHttpResponseData() {
        class MockURLProtocol: URLProtocol {
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: "1.1", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: "Unauthorized".data(using: .utf8)!)
                client?.urlProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret")
        
        setURLProtocol(MockURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUser = expectation(description: "User")
        
        User.signup(username: "test", password: "test") { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .invalidResponse(let httpResponse, let data):
                    XCTAssertNotNil(httpResponse)
                    if let httpResponse = httpResponse {
                        XCTAssertEqual(httpResponse.statusCode, 401)
                    }
                    
                    XCTAssertNotNil(data)
                    if let data = data, let responseStringBody = String(data: data, encoding: .utf8) {
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
        
        waitForExpectations(timeout: 30) { error in
            expectationUser = nil
        }
    }
    
}
