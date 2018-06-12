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
    
    func testObjectIDMissing() {
        let expectedDescription = "Object ID is required and is missing"
        XCTAssertEqual("\(Kinvey.Error.objectIdMissing)", expectedDescription)
        XCTAssertEqual(Kinvey.Error.objectIdMissing.description, expectedDescription)
        XCTAssertEqual(Kinvey.Error.objectIdMissing.localizedDescription, expectedDescription)
        XCTAssertEqual(Kinvey.Error.objectIdMissing.failureReason, expectedDescription)
        XCTAssertEqual((Kinvey.Error.objectIdMissing as NSError).localizedDescription, expectedDescription)
        XCTAssertEqual((Kinvey.Error.objectIdMissing as NSError).localizedFailureReason, expectedDescription)
        XCTAssertNil(Kinvey.Error.objectIdMissing.responseStringBody)
        XCTAssertNil(Kinvey.Error.objectIdMissing.httpResponse)
        XCTAssertNil(Kinvey.Error.objectIdMissing.responseBodyJsonDictionary)
    }
    
    func testInvalidResponse() {
        XCTAssertEqual(Kinvey.Error.invalidResponse(httpResponse: nil, data: nil).description, "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual(Kinvey.Error.unauthorized(httpResponse: nil, data: nil, error: "Error", debug: "Debug", description: "Description").description, "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual(Kinvey.Error.noActiveUser.description, "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual(Kinvey.Error.requestCancelled.description, "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual(Kinvey.Error.invalidDataStoreType.description, "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual(Kinvey.Error.userWithoutEmailOrUsername.description, "User has no email or username")
    }
    
    func testInvalidResponseHttpResponseData() {
        let response = "Unauthorized"
        let requestId = UUID().uuidString
        mockResponse(
            statusCode: 401,
            headerFields: [
                KinveyHeaderField.requestId.rawValue : requestId
            ],
            string: response
        )
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationUser = expectation(description: "User")
        
        User.signup(username: "test", password: "test", options: nil) {
            switch $0 {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error is Kinvey.Error)
                XCTAssertNotNil(error as? Kinvey.Error)
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .invalidResponse(let httpResponse, let data):
                        XCTAssertNotNil(httpResponse)
                        if let httpResponse = httpResponse {
                            XCTAssertEqual(httpResponse.statusCode, 401)
                        }
                        
                        XCTAssertNotNil(data)
                        if let data = data, let responseStringBody = String(data: data, encoding: .utf8) {
                            XCTAssertEqual(responseStringBody, response)
                        }
                        XCTAssertEqual(error.responseStringBody, response)
                        XCTAssertEqual(error.requestId, requestId)
                        XCTAssertEqual(httpResponse?.allHeaderFields[KinveyHeaderField.requestId] as? String, requestId)
                    default:
                        XCTFail()
                    }
                    
                    XCTAssertNotNil(error.httpResponse)
                    if let httpResponse = error.httpResponse {
                        XCTAssertEqual(httpResponse.statusCode, 401)
                    }
                }
            }
            
            expectationUser?.fulfill()
        }
        
        waitForExpectations(timeout: 30) { error in
            expectationUser = nil
        }
    }
    
}
