//
//  ErrorTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class ErrorTestCase: XCTestCase {
    
    func testObjectIDMissing() {
        XCTAssertEqual(Error.ObjectIdMissing.description, "Object ID is required and is missing")
    }
    
    func testInvalidResponse() {
        XCTAssertEqual(Error.InvalidResponse.description, "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual(Error.Unauthorized(error: "Error", description: "Description").description, "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual(Error.NoActiveUser.description, "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual(Error.RequestCancelled.description, "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual(Error.InvalidDataStoreType.description, "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual(Error.UserWithoutEmailOrUsername.description, "User has no email or username")
    }
    
}
